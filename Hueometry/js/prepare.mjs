// Runs on a WorkerScript thread: builds a puzzle from its reference (which
// regenerates the board with the engine), so the interface never waits on
// it. Expert boards take about half a second in Qt's engine.
import * as S from "./session.mjs";

WorkerScript.onMessage = function (m) {
  WorkerScript.sendMessage({ token: m.token, puzzle: S.puzzle(m.ref) });
};
