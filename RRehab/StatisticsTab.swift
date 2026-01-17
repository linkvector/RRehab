import SwiftUI
import SwiftData
import Charts

struct StatisticsTab: View {
    @EnvironmentObject var appState: AppState
    @Query(sort: \TrainingRecord.timestamp, order: .forward) private var allRecords: [TrainingRecord]
    
    @State private var selectedActivity: ActivityType = .grip
    @State private var selectedTimeRange: TimeRange = .hour
    
    enum TimeRange: String, CaseIterable {
        case hour = "小时", week = "周", month = "月", year = "年"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    headerSelectors
                    
                    if filteredRecords.isEmpty {
                        ContentUnavailableView("暂无数据", systemImage: "chart.bar", description: Text("完成训练并保存后将显示报告"))
                            .padding(.top, 50)
                    } else {
                        chartContainer
                        summaryView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("统计中心")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    // MARK: - 图表容器
    @ViewBuilder
    private var chartContainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleForSelectedRange)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if selectedTimeRange == .hour {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        // 给容器一个 ID，确保可以滚动
                        renderChart(data: generate24HourData())
                            .frame(width: 1000, height: 260)
                    }
                    .onAppear {
                        let currentHourLabel = String(format: "%02d:00", Calendar.current.component(.hour, from: Date()))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo(currentHourLabel, anchor: .center)
                            }
                        }
                    }
                }
            } else if selectedTimeRange == .month {
                let data = generateMonthDayData()
                let slotWidth: CGFloat = 45
                let totalWidth = CGFloat(data.count) * slotWidth
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        renderChart(data: data)
                            .frame(width: totalWidth, height: 260)
                    }
                    .onAppear {
                        let currentDayLabel = String(format: "%02d日", Calendar.current.component(.day, from: Date()))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo(currentDayLabel, anchor: .center)
                            }
                        }
                    }
                }
            } else {
                renderChart(data: selectedTimeRange == .week ? generate7DayData() : generateYearMonthData())
                    .frame(height: 260)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - 通用渲染引擎
    private func renderChart(data: [ReportEntry]) -> some View {
        Chart {
            ForEach(data) { entry in
                BarMark(
                    x: .value("时间", entry.label),
                    y: .value("次数", entry.totalCount),
                    width: (selectedTimeRange == .hour || selectedTimeRange == .month) ? .fixed(22) : .automatic
                )
                .foregroundStyle(activityColor.gradient)
                .cornerRadius(4)
                .annotation(position: .top) {
                    if entry.totalCount > 0 {
                        Text("\(entry.totalCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(activityColor)
                    }
                }
            }
        }
        // 关键修复：chartXSelection 或使用 chartXAxis 来标记 ID 是不行的
        // 我们通过在 Chart 外部包裹或使用这种技巧来确保 ScrollViewReader 能找到 ID
        .chartXAxis {
            if selectedTimeRange == .hour {
                AxisMarks(values: data.map { $0.label }) { value in
                    if let label = value.as(String.self), label.hasSuffix(":00") {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
            } else {
                AxisMarks()
            }
        }
        // 为了让 ScrollViewReader 找到 ID，我们将 ID 映射到 X 轴的视图上
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(.clear)
                    .onAppear {
                        // 这里的逻辑通常用于手势，但为了简单的 ID 滚动，
                        // 我们在 ForEach 内部处理即可。
                    }
            }
        }
        // 修正：在 Chart 后面使用背景视图来承载 ID 锚点（最稳妥的办法）
        .background {
            HStack(spacing: 0) {
                ForEach(data) { entry in
                    Color.clear
                        .frame(width: (selectedTimeRange == .hour || selectedTimeRange == .month) ? (selectedTimeRange == .hour ? 1000/24.0 : (CGFloat(data.count)*45)/CGFloat(data.count)) : 0)
                        .id(entry.label)
                }
            }
        }
    }
    
    // MARK: - 数据生成逻辑
    private func generate24HourData() -> [ReportEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecords = filteredRecords.filter { $0.timestamp >= today }
        return (0...23).map { hour in
            let label = String(format: "%02d:00", hour)
            let count = todayRecords.filter { calendar.component(.hour, from: $0.timestamp) == hour }.reduce(0) { $0 + $1.count }
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today)
        }
    }
    
    private func generate7DayData() -> [ReportEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today)!
        let rangeDays = (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        return rangeDays.map { day in
            let label = day.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
            let count = filteredRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }.reduce(0) { $0 + $1.count }
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: day)
        }
    }
    
    private func generateMonthDayData() -> [ReportEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let range = calendar.range(of: .day, in: .month, for: now)!
        return range.compactMap { day -> ReportEntry in
            let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            let label = String(format: "%02d日", day)
            let count = filteredRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.reduce(0) { $0 + $1.count }
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: date)
        }
    }
    
    private func generateYearMonthData() -> [ReportEntry] {
        let calendar = Calendar.current
        let now = Date()
        return (1...12).map { month in
            let label = String(format: "%02d月", month)
            let count = filteredRecords.filter {
                calendar.component(.year, from: $0.timestamp) == calendar.component(.year, from: now) &&
                calendar.component(.month, from: $0.timestamp) == month
            }.reduce(0) { $0 + $1.count }
            var components = calendar.dateComponents([.year], from: now)
            components.month = month; components.day = 1
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: calendar.date(from: components) ?? now)
        }
    }

    // MARK: - UI 组件
    private var titleForSelectedRange: String {
        switch selectedTimeRange {
        case .hour: return "今日 24 小时分布"
        case .week: return "近 7 天趋势"
        case .month: return "本月每日趋势"
        case .year: return "今年每月趋势"
        }
    }

    private var headerSelectors: some View {
        VStack(spacing: 15) {
            Picker("项目", selection: $selectedActivity) {
                Text("握力").tag(ActivityType.grip)
                Text("悬臂").tag(ActivityType.armWakeup)
                Text("转腕").tag(ActivityType.wrist)
            }.pickerStyle(.segmented)
            
            Picker("维度", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.palette)
        }.padding(.horizontal)
    }

    private var summaryView: some View {
        HStack(spacing: 15) {
            summaryCard(title: "累计次数", value: "\(totalCount)", color: activityColor)
            summaryCard(title: "被提醒", value: "\(totalWarnings)", color: .orange)
        }.padding(.horizontal)
    }
    
    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(12)
    }

    private var filteredRecords: [TrainingRecord] { allRecords.filter { $0.typeName == selectedActivity.rawValue } }
    private var totalCount: Int { filteredRecords.reduce(0) { $0 + $1.count } }
    private var totalWarnings: Int { filteredRecords.reduce(0) { $0 + $1.warningCount } }
    private var activityColor: Color {
        switch selectedActivity {
        case .grip: return .green
        case .armWakeup: return .orange
        case .wrist: return .blue
        }
    }
}

// MARK: - 数据模型
struct ReportEntry: Identifiable {
    var id: String { label }
    let label: String
    let totalCount: Int
    let totalWarnings: Int
    let sortOrder: Date
}
