import SwiftUI

struct WristRotationView: View {
    var body: some View {
        VStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text("转腕训练")
                .font(.title2)
            Text("开发中...")
                .foregroundColor(.gray)
        }
    }
}
