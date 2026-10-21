import SwiftUI

/// Connection skeleton (plan step 01) and the base of the connection setup screen
/// (plan step 03).
///
/// The address is validated locally. The OAuth -> Ingress chain is not implemented yet,
/// so a valid address produces an explicit "not in this build" card rather than a fake
/// success. No token, cookie or session URL is ever shown here.
struct ConnectionSetupView: View {
    @Bindable var connection: ConnectionController

    var body: some View {
        Form {
            Section {
                TextField("http://homeassistant.local:8123", text: $connection.address)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .accessibilityIdentifier(AccessibilityID.connectionAddressField)
            } header: {
                Text("Home Assistant 地址")
            } footer: {
                Text("请输入 Home Assistant 的完整地址。原型只支持一个实例、一个账号。")
            }

            Section {
                Button("连接") {
                    connection.connect()
                }
                .accessibilityIdentifier(AccessibilityID.connectionConnectButton)

                if let progress = connection.state.progressDescription {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(progress)
                    }
                    .accessibilityIdentifier(AccessibilityID.connectionProgress)
                }
            }

            if let problem = connection.state.problem {
                Section {
                    ConnectionProblemCard(problem: problem)
                        .accessibilityIdentifier(AccessibilityID.connectionProblemCard)
                }
            }

            Section {
                Text("步骤 01 只包含界面骨架。HA 登录、Ingress 会话与业务读取在步骤 03–04 接入；在此之前界面不会显示任何伪造的连接状态。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("连接")
        .accessibilityIdentifier(AccessibilityID.connectionSetupRoot)
    }
}

#Preview {
    NavigationStack {
        ConnectionSetupView(connection: ConnectionController())
    }
}
