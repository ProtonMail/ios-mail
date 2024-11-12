import SwiftUI

extension View {

    func deletionAlert(
        alert: Alert,
        isPresented: Binding<Bool>,
        confirm: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) -> some View {
        self.alert(
            alert.title.string,
            isPresented: isPresented,
            actions: {
                Button(L10n.Contacts.DeletionAlert.confirm.string, role: .destructive, action: confirm)
                Button(L10n.Contacts.DeletionAlert.cancel.string, role: .cancel, action: cancel)
            },
            message: { Text(alert.message) }
        )
    }

}
