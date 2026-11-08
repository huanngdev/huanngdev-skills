# UI

## Design principles — minimal, focused, dense
- One surface level. **Never a card inside a card** (or panel in panel). Group with spacing and headings first.
- Few borders: only for inputs and to separate genuinely different regions. No decorative borders, shadows, gradients or background tints stacked together.
- Tight spacing to maximize usable screen: small paddings/gaps from the token scale (`p-2`/`p-3`, `gap-2`/`gap-3`, small page padding). No big empty hero blocks or oversized headers.
- One primary action per view; secondary actions quieter (ghost/outline, menus).
- Less text and chrome: labels short, helper text only when needed, icons with text only where they add meaning.
- Before adding a visual element, ask what the user must focus on; remove what competes with it.

## shadcn/ui
- New app: `bunx --bun shadcn@latest init --preset b0 --template vite --pointer`, then `bunx --bun shadcn@latest add --all -y` so every component is available from the start. Later additions: `bunx --bun shadcn@latest add <name>`.
- `components/ui/*` are generated (Base UI primitives): regenerate via the CLI, don't hand-edit. Compose them in feature components.
- Theme tokens only (`bg-background`, `text-muted-foreground`, …). No raw colors, arbitrary values (`w-[317px]`) or inline styles.

## Components come only from shadcn and its ecosystem
- Every UI element is a shadcn/ui component (`components/ui/*`) or composed from them in a feature component. Find one in this order: installed `components/ui` → shadcn docs (MCP `shadcn`, `shadcn docs <name>`) → shadcn blocks/charts → registries in the shadcn Registry Directory (`bunx --bun shadcn@latest search <query>`, `add @<registry>/<item>`).
- Community registry items: read the code before keeping it; one that adds npm dependencies follows the ask-first rule (`hd-core` workflow.md).
- Nothing fits → stop and ask the user, naming what you searched. Never hand-roll a small component that duplicates a shadcn one (button, badge, spinner, kbd, tooltip, dialog, empty state, field, …).
- Need a variant → compose with `className` and theme tokens in the feature component; never fork or edit `components/ui`.

## Landing & marketing pages
- Public site pages (landing, pricing, company, product pages) also use the vendor skill `design-taste-frontend` for art direction, imagery and its browser check (hd-index docs sources: Taste Skill).
- App screens (dashboards, forms, settings, tables) follow only this file: minimal and dense.
- On conflict this file wins: shadcn components and theme tokens stay; the taste skill shapes type, color, layout and imagery, not the component set.

## Tailwind CSS v4
- CSS-first config: global CSS has `@import "tailwindcss";` + `@import "shadcn/tailwind.css";` and the tokens in `@theme` / CSS variables. No `tailwind.config.js`.
- New design tokens go in the global CSS (`@theme`), never as arbitrary values in components.

## Scrolling
- Every scrollable region uses shadcn `ScrollArea` with a scroll fade. `ScrollArea` has no fade prop: `scroll-fade` (from `shadcn/tailwind.css`) must sit on its viewport, so add it through the root: `<ScrollArea className="*:data-[slot=scroll-area-viewport]:scroll-fade">` (horizontal: `…:scroll-fade-x`).
- Write that once in `components/scroll-region.tsx` (a wrapper around `ScrollArea`, outside `components/ui/`) and use the wrapper everywhere.
- Never `overflow-auto`/`overflow-scroll` on a div for content. Layouts fill the viewport (`h-dvh`) and scroll inside regions, not the whole page.

## Theme
- Dark mode follows the system by default (`prefers-color-scheme`); a light/dark/system toggle may override it (stored per user/device).
- Check every screen in both themes.

## Building blocks
- Icons: lucide-react. Toasts: sonner. Animation: motion — short and subtle, respects reduced motion. Dates: date-fns. Charts: recharts.
- Loading = skeletons shaped like the content; empty = one line + the primary action; error = message + retry.
- Mobile-first; check 375px, 768px, 1280px. No horizontal page scroll.
