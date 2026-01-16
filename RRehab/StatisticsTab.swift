import SwiftUI
import SwiftData
import Charts

struct StatisticsTab: View {
    // 1. 获取原子数据
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
                    // 头部维度切换
                    headerSelectors
                    
                    if filteredRecords.isEmpty {
                        ContentUnavailableView("暂无数据", systemImage: "chart.bar", description: Text("完成训练并保存后将显示报告"))
                            .padding(.top, 50)
                    } else {
                        // 2. 核心图表区
                        chartContainer
                        
                        // 3. 数据汇总
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
                // 专项优化：24小时横向滚动图表
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        renderChart(data: generate24HourData())
                            .frame(width: 1000, height: 260) // 固定宽度确保24个柱子布局
                            .id("RIGHT_ANCHOR") // 右侧锚点
                    }
                    .onAppear {
                        // 自动对齐到最右侧（当前小时）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo("RIGHT_ANCHOR", anchor: .trailing)
                            }
                        }
                    }
                }
            } else {
                let data: [ReportEntry] = {
                    switch selectedTimeRange {
                    case .week:
                        return generate7DayData()
                    case .month:
                        return generateMonthDayData()
                    case .year:
                        return generateYearMonthData()
                    case .hour:
                        return []
                    }
                }()
                
                if selectedTimeRange == .month {
                    // 月视图：横向滚动，进入时将“当天”停在最右侧
                    let slotWidth: CGFloat = 40 // 每个日期格子的总槽位宽度
                    let totalWidth = CGFloat(data.count) * slotWidth
                    let currentDay = Calendar.current.component(.day, from: Date())
                    let currentDayLabel = String(format: "%02d日", currentDay)
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            renderChart(data: data)
                                .frame(width: totalWidth, height: 260)
                                .id(currentDayLabel)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(currentDayLabel, anchor: .trailing)
                                }
                            }
                        }
                    }
                } else if selectedTimeRange == .year {
                    // 年视图：横向滚动并自动滚动到当下月份
                    let slotWidth: CGFloat = 60 // 每个月的槽位宽度，保证可读性
                    let totalWidth = CGFloat(data.count) * slotWidth
                    // 以“当前月份标签”为锚点，例如 01月、02月 ... 12月
                    let currentMonthIndex = Calendar.current.component(.month, from: Date())
                    let currentMonthLabel = String(format: "%02d月", currentMonthIndex)
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            renderChart(data: data)
                                .frame(width: totalWidth, height: 260)
                                .id(currentMonthLabel)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(currentMonthLabel, anchor: .trailing)
                                }
                            }
                        }
                    }
                } else {
                    renderChart(data: data)
                        .frame(height: 260)
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var titleForSelectedRange: String {
        switch selectedTimeRange {
        case .hour:
            return "今日 24 小时分布 (向左滑动查看)"
        case .week:
            return "近 7 天趋势"
        case .month:
            return "本月每日趋势"
        case .year:
            return "今年每月趋势"
        }
    }
    
    // MARK: - 通用渲染引擎
    private func renderChart(data: [ReportEntry]) -> some View {
        Chart {
            ForEach(data) { entry in
                if selectedTimeRange == .hour {
                    BarMark(
                        x: .value("时间", entry.label),
                        y: .value("次数", entry.totalCount),
                        width: .fixed(22)
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
                } else {
                    if selectedTimeRange == .month {
                        BarMark(
                            x: .value("时间", entry.label),
                            y: .value("次数", entry.totalCount),
                            width: .fixed(22)
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
                    } else {
                        BarMark(
                            x: .value("时间", entry.label),
                            y: .value("次数", entry.totalCount)
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
            }
        }
        .chartXAxis {
            switch selectedTimeRange {
            case .hour:
                AxisMarks(values: data.map { $0.label }) { value in
                    if let label = value.as(String.self), label.hasSuffix(":00") {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
            case .week, .month, .year:
                AxisMarks()
            }
        }
    }
    
    // MARK: - 数据聚合逻辑
    
    private func generate24HourData() -> [ReportEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecords = filteredRecords.filter { $0.timestamp >= today }
        
        return (0...23).map { hour in
            let label = String(format: "%02d:00", hour)
            let count = todayRecords
                .filter { calendar.component(.hour, from: $0.timestamp) == hour }
                .reduce(0) { $0 + $1.count }
            
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today)
        }
    }
    
    private func generate7DayData() -> [ReportEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today)!
        let rangeDays = (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let records = filteredRecords.filter { $0.timestamp >= start && $0.timestamp < calendar.date(byAdding: .day, value: 1, to: today)! }
        return rangeDays.map { day in
            let label = day.formatted(Date.FormatStyle().month(.twoDigits).day(.twoDigits))
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let dayRecords = records.filter { $0.timestamp >= day && $0.timestamp < dayEnd }
            let count = dayRecords.reduce(0) { $0 + $1.count }
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: day)
        }
    }
    
    private func generateMonthDayData() -> [ReportEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let range = calendar.range(of: .day, in: .month, for: now)!
        let records = filteredRecords.filter { $0.timestamp >= startOfMonth }
        return range.compactMap { day -> ReportEntry in
            let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            let next = calendar.date(byAdding: .day, value: 1, to: date)!
            let label = String(format: "%02d日", day)
            let dayRecords = records.filter { $0.timestamp >= date && $0.timestamp < next }
            let count = dayRecords.reduce(0) { $0 + $1.count }
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: date)
        }
    }
    
    private func generateYearMonthData() -> [ReportEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        let records = filteredRecords.filter { $0.timestamp >= startOfYear }
        return (1...12).map { month -> ReportEntry in
            var components = calendar.dateComponents([.year], from: now)
            components.month = month
            components.day = 1
            let date = calendar.date(from: components)!
            let next = calendar.date(byAdding: .month, value: 1, to: date)!
            let monthRecords = records.filter { $0.timestamp >= date && $0.timestamp < next }
            let count = monthRecords.reduce(0) { $0 + $1.count }
            let label = String(format: "%02d月", month)
            return ReportEntry(label: label, totalCount: count, totalWarnings: 0, sortOrder: date)
        }
    }

    // MARK: - UI 组件与计算属性
    
    private var headerSelectors: some View {
        VStack(spacing: 15) {
            Picker("项目", selection: $selectedActivity) {
                Text("握力").tag(ActivityType.grip)
                Text("悬臂").tag(ActivityType.armWakeup)
                Text("转腕").tag(ActivityType.wrist)
            }.pickerStyle(.segmented)
            
            Picker("维度", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
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
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var filteredRecords: [TrainingRecord] {
        allRecords.filter { $0.typeName == selectedActivity.rawValue }
    }
    
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

// MARK: - 数据模型 (放在结构体外，确保作用域正确)
struct ReportEntry: Identifiable {
    var id: String { label }
    let label: String
    let totalCount: Int
    let totalWarnings: Int
    let sortOrder: Date
}

