const test = require("node:test");
const assert = require("node:assert/strict");
const {
  acceptedBetStatus,
  mapSelectionToPinnacleTeam,
  validateRiskControls,
} = require("../lib/pinnacle_logic");

test("mapeia casa e visitante respeitando homeTeamType", () => {
  assert.equal(mapSelectionToPinnacleTeam("TEAM1", "TEAM1"), "TEAM1");
  assert.equal(mapSelectionToPinnacleTeam("TEAM2", "TEAM1"), "TEAM2");
  assert.equal(mapSelectionToPinnacleTeam("TEAM1", "TEAM2"), "TEAM2");
  assert.equal(mapSelectionToPinnacleTeam("TEAM2", "TEAM2"), "TEAM1");
  assert.equal(mapSelectionToPinnacleTeam("DRAW", "TEAM2"), "DRAW");
});

test("rejeita configuração de risco insegura", () => {
  assert.throws(() => validateRiskControls({
    stake: 10,
    maxStake: 5,
    minBalance: 20,
    minConfidence: 80,
  }));
  assert.throws(() => validateRiskControls({
    stake: 5,
    maxStake: 5,
    minBalance: -1,
    minConfidence: 80,
  }));
});

test("aceita somente estados que ainda podem representar ordem válida", () => {
  assert.equal(acceptedBetStatus("ACCEPTED"), true);
  assert.equal(acceptedBetStatus("PENDING_ACCEPTANCE"), true);
  assert.equal(acceptedBetStatus("PROCESSED_WITH_ERROR"), false);
  assert.equal(acceptedBetStatus("NOT_ACCEPTED"), false);
});
