export type PinnacleTeam = "TEAM1" | "TEAM2" | "DRAW";

export function mapSelectionToPinnacleTeam(
    selectedSide: string,
    homeTeamType: string
): PinnacleTeam {
    const side = selectedSide.trim().toUpperCase();
    const home = homeTeamType.trim().toUpperCase();
    if (side === "DRAW") return "DRAW";
    if (side !== "TEAM1" && side !== "TEAM2") {
        throw new Error("Seleção da IA inválida.");
    }
    if (home !== "TEAM1" && home !== "TEAM2") {
        throw new Error("homeTeamType da liga inválido.");
    }
    const selectedHome = side === "TEAM1";
    if (selectedHome) return home as PinnacleTeam;
    return home === "TEAM1" ? "TEAM2" : "TEAM1";
}

export function validateRiskControls(input: {
    stake: number;
    maxStake: number;
    minBalance: number;
    minConfidence: number;
}) {
    const { stake, maxStake, minBalance, minConfidence } = input;
    if (![stake, maxStake, minBalance, minConfidence].every(Number.isFinite)) {
        throw new Error("Configuração numérica do robô inválida.");
    }
    if (stake <= 0 || maxStake <= 0 || stake > maxStake) {
        throw new Error("Stake inválida ou acima do limite máximo configurado.");
    }
    if (minBalance < 0 || minConfidence < 0 || minConfidence > 100) {
        throw new Error("Limites de saldo ou confiança inválidos.");
    }
}

export function acceptedBetStatus(status: unknown): boolean {
    return status === "ACCEPTED" || status === "PENDING_ACCEPTANCE";
}
