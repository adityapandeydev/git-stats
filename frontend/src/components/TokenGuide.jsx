export default function TokenGuide() {
  return <details className="token-guide"><summary>Which tokens do I need?</summary>
    <p><strong>Preview only:</strong> use a read-only token. Manual workflow export needs no write token.</p>
    <p><strong>Commit from Studio:</strong> use a temporary token with Contents, Workflows, and Actions write permissions, selecting only your engine fork. Revoke it after setup. A fine-grained token applies the same permissions to every selected repository; keep a separate read-only preview token when you need broader private-repository access.</p>
    <p><strong>Scheduled generation:</strong> create a separate, longer-lived read token and add it as the fork’s Actions secret named <code>GH_TOKEN</code>. Give it access only to the repositories needed for your stats. Set an expiration and renew the secret before it expires. Studio does not create or store this secret.</p>
    <p>GitHub Actions uses its own repository token to commit generated SVGs. Your read secret does not need write permissions.</p>
    <a href="https://github.com/settings/personal-access-tokens/new" target="_blank" rel="noreferrer">Create a fine-grained token</a>{' · '}<a href="https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens" target="_blank" rel="noreferrer">Token setup guide</a>
  </details>
}
