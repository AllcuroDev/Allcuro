import { loginPrompt } from '../state/auth'
import { LoginForm } from './LoginForm'
import { Modal } from './ui'
import { toast } from '../lib/toast'

/** The app's QuickLoginSheet: opened by `requireLogin()` when a guest tries to book. */
export function LoginDialog() {
  const prompt = loginPrompt.use()
  if (!prompt) return null

  const close = () => loginPrompt.set(null)

  return (
    <Modal onClose={close} labelledBy="login-dlg-title">
      <div className="login-dlg-intro">
        <strong>{prompt.title}</strong>
        <span>{prompt.subtitle}</span>
      </div>
      <LoginForm
        headingId="login-dlg-title"
        onDone={() => {
          close()
          toast('✓ Signed in. You can now continue booking.')
          prompt.onSuccess?.()
        }}
      />
    </Modal>
  )
}
