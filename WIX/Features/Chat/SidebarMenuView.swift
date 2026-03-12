import SwiftUI

struct SidebarMenuView: View {

    @Binding var isOpen: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isOpen = false
                }

            menu
        }
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 26) {

            Text("WIX")
                .font(.largeTitle.bold())

            SidebarItem(icon: "bubble.left.and.bubble.right", title: "Chat")

            SidebarItem(icon: "photo.on.rectangle", title: "Kirjasto")

            SidebarItem(icon: "gearshape", title: "Asetukset")

            Spacer()

        }
        .padding(24)
        .frame(width: 270)
        .background(
            LinearGradient(
                colors: [.black, Color(white: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct SidebarItem: View {

    var icon: String
    var title: String

    var body: some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 20))

            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
    }
}
