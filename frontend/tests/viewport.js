/**
 * Shrinks the story iframe to a phone viewport, for stories that measure layout.
 *
 * Two things this exists to get right:
 *  - The VIEWPORT has to shrink, not a wrapper element. MUI breakpoints are media queries,
 *    so a 390px-wide Box inside a desktop-width iframe still renders every `md` branch.
 *  - The import has to be lazy. At module scope `@vitest/browser/context` throws
 *    "can be imported only inside the Browser Mode", which breaks the story for anyone who
 *    opens it in the Storybook app rather than the test runner.
 *
 * Returns false when there is no runner driving the iframe, so a play function can skip
 * measurements that would otherwise assert against a desktop width.
 */
export const shrinkToPhoneViewport = async (width = 390, height = 844) => {
  try {
    const { page } = await import("@vitest/browser/context");
    await page.viewport(width, height);
    return true;
  } catch {
    return false;
  }
};
