const assert = require("node:assert/strict")
const TrayModel = require("../TrayModel.js")

// The provisional slot must remain a valid target after the last pinned icon
// moves into the drawer. This is the exact geometry of that empty tray state.
assert.equal(TrayModel.pinnedDropHit(95, 100, 0, 10, true), true)
assert.equal(TrayModel.pinnedDropHit(89, 100, 0, 10, true), false)
assert.equal(TrayModel.pinnedDropHit(95, 100, 0, 10, false), false)

// Existing pinned icons and the provisional slot form one contiguous target.
assert.equal(TrayModel.pinnedDropHit(75, 100, 2, 10, true), true)
assert.equal(TrayModel.pinnedDropHit(69, 100, 2, 10, true), false)

// The function is axis-agnostic, so callers can supply width or height.
assert.equal(TrayModel.pinnedDropHit(195, 200, 0, 10, true), true)

// Pinning is independent of reordering: dropping the last drawer item into
// the final pinned slot leaves order unchanged but must still alter membership.
assert.equal(TrayModel.movedBefore(["other", "TelegramDesktop"], "TelegramDesktop", ""), null)
assert.deepEqual(TrayModel.changedMembership([], "TelegramDesktop", true), ["TelegramDesktop"])
assert.deepEqual(
  TrayModel.changedMembership(["TelegramDesktop"], "TelegramDesktop", false),
  []
)
assert.equal(TrayModel.changedMembership(["TelegramDesktop"], "TelegramDesktop", true), null)

// The management UI exposes three mutually-exclusive placements. Pinning a
// hidden icon must reveal it; hiding a pinned icon must unpin it; either
// action can be toggled back to the drawer.
assert.deepEqual(
  TrayModel.setIconPlacement([], ["TelegramDesktop"], "TelegramDesktop", "pinned"),
  { pinned: ["TelegramDesktop"], hidden: [] }
)
assert.deepEqual(
  TrayModel.setIconPlacement(["TelegramDesktop"], [], "TelegramDesktop", "hidden"),
  { pinned: [], hidden: ["TelegramDesktop"] }
)
assert.deepEqual(
  TrayModel.setIconPlacement(["TelegramDesktop"], [], "TelegramDesktop", "drawer"),
  { pinned: [], hidden: [] }
)

console.log("tray model tests passed")
