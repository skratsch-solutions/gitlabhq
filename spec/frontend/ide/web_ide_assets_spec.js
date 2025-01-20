import nodePath from 'node:path';
import nodeFs from 'node:fs/promises';

describe('asset patching in @gitlab/web-ide', () => {
  const PATH_PUBLIC_VSCODE = nodePath.join(
    nodePath.dirname(require.resolve('@gitlab/web-ide')),
    'public/vscode',
  );
  const PATH_EXTENSION_HOST_HTML = nodePath.join(
    PATH_PUBLIC_VSCODE,
    'out/vs/workbench/services/extensions/worker/webWorkerExtensionHostIframe.html',
  );

  it('prevents xss by patching parentOrigin in webIdeExtensionHost.html', async () => {
    const content = await nodeFs.readFile(PATH_EXTENSION_HOST_HTML, { encoding: 'utf-8' });

    // https://gitlab.com/gitlab-org/security/gitlab-web-ide-vscode-fork/-/issues/1#note_1905417620
    expect(content).toContain('const parentOrigin = window.origin;');
  });

  it('contains vscode/node_modules', async () => {
    // Yarn was doing weird stuff when trying to include a directory called `node_modules`
    // We think we've worked around this, but let's add a test just in case.
    // https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/400
    const stat = await nodeFs.stat(`${PATH_PUBLIC_VSCODE}/node_modules`);

    expect(stat.isDirectory()).toBe(true);
  });

  it('doesnt have extraneous html files', async () => {
    const allChildren = await nodeFs.readdir(PATH_PUBLIC_VSCODE, {
      encoding: 'utf-8',
      recursive: true,
    });
    const htmlChildren = allChildren.filter((x) => x.endsWith('.html'));

    /**
     * ## What in the world is this test doing!?
     *
     * This test was introduced when we were fixing a [security vulnerability][1] related to GitLab self-hosting
     * problematic `.html` files. These files could be exploited through an `iframe` on an `evil.com` and will
     * assume the user's cookie authentication. Boom!
     *
     * ## How do I know if an `.html` file is vulnerable?
     *
     * - The `.html` file used the `postMessage` API and allowed any `origin` which enabled any external site to
     *   open it in an `iframe` and communicate to it.
     * - The `iframe` exposed some internal VSCode message bus that could allow arbitrary requests. So watch out for
     *   `fetch`.
     *
     * [1]: https://gitlab.com/gitlab-org/security/gitlab-web-ide-vscode-fork/-/issues/1#note_1905417620
     *
     * ========== If expectation fails and you can't see the full comment... LOOK UP! ==============
     */
    expect(htmlChildren).toEqual([
      // This is the only HTML file we expect and it's protected by the other test.
      'out/vs/workbench/services/extensions/worker/webWorkerExtensionHostIframe.html',
      // HTML files from "extensions" should be safe (since they only work in an extension host environment really).
      // We're going to list them out here though to err on the side of caution.
      'extensions/microsoft-authentication/media/index.html',
      'extensions/gitlab-vscode-extension/webviews/security_finding/index.html',
      'extensions/gitlab-vscode-extension/webviews/gitlab_duo_chat/index.html',
      'extensions/gitlab-vscode-extension/assets/language-server/webviews/duo-workflow/index.html',
      'extensions/gitlab-vscode-extension/assets/language-server/webviews/duo-chat/index.html',
      'extensions/gitlab-vscode-extension/assets/language-server/webviews/chat/index.html',
      'extensions/github-authentication/media/index.html',
    ]);
  });
});
