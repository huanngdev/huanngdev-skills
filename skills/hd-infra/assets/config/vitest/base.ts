import { defineConfig } from "vitest/config";

// tests live in test/ mirroring src/ (hd-core testing.md)
export const base = defineConfig({
  test: { include: ["test/**/*.test.{ts,tsx}"], restoreMocks: true },
});
