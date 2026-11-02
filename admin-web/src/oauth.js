export function googleSignInOptions(origin) {
  const url = new URL(origin);
  if (url.protocol !== 'https:' && !['localhost','127.0.0.1'].includes(url.hostname)) {
    throw new Error('Google sign-in requires a secure website.');
  }
  return {provider:'google',options:{redirectTo:url.origin+'/',queryParams:{prompt:'select_account'}}};
}

// Explicit PKCE exchange avoids racing automatic URL detection and application
// startup. Credentials and error details are removed from browser history.
export async function finishGoogleSignIn(auth, href, replaceUrl) {
  const url=new URL(href);
  const hash=new URLSearchParams(url.hash.slice(1));
  const code=url.searchParams.get('code');
  const failed=url.searchParams.has('error')||hash.has('error');
  if(!code&&!failed)return;
  try {
    if(failed)throw new Error('Google sign-in was cancelled or could not be completed. Please try again.');
    const {error}=await auth.exchangeCodeForSession(code);
    if(error)throw new Error('The Google sign-in link expired or could not be verified. Start Google sign-in again in this tab.');
  } finally {
    ['code','state','error','error_code','error_description'].forEach(k=>url.searchParams.delete(k));
    url.hash='';
    replaceUrl(url.pathname+url.search);
  }
}
