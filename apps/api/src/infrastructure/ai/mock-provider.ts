import { AIQuestionProvider } from "./ai-provider.interface";
import { GeneratedQuestion, GeneratedQuestionBatch, QuestionDraftRequest } from "./types";
import { shuffleQuestionOptions } from "./utils/shuffle-options";

/**
 * Deterministic Mock Provider for Unit Tests, CI/CD, and Local Development
 */
export class MockQuestionProvider implements AIQuestionProvider {
  public readonly providerName = "MOCK";

  async generateDraftQuestions(request: QuestionDraftRequest): Promise<GeneratedQuestionBatch> {
    const count = request.count || 1;
    const questions: GeneratedQuestion[] = [];

    for (let i = 1; i <= count; i++) {
      if (request.examCode === "NEET_UG") {
        const baseQuestion: GeneratedQuestion = {
          questionText: `Which of the following cellular organelles is primarily responsible for ATP synthesis via oxidative phosphorylation in human hepatocytes? (Draft #${i} - ${request.subject})`,
          difficulty: request.difficulty,
          subject: request.subject,
          topic: request.topic,
          subtopic: request.subtopic,
          options: [
            {
              optionKey: "A",
              optionText: "Mitochondrion (inner membrane cristae)",
              isCorrect: true,
            },
            {
              optionKey: "B",
              optionText: "Lysosome containing hydrolytic enzymes",
              isCorrect: false,
            },
            {
              optionKey: "C",
              optionText: "Smooth endoplasmic reticulum for lipid synthesis",
              isCorrect: false,
            },
            { optionKey: "D", optionText: "Golgi apparatus cisternal stacks", isCorrect: false },
          ],
          correctOptionKey: "A",
          explanation:
            "The mitochondrion contains ATP synthase complex V on the inner mitochondrial membrane, driving oxidative phosphorylation. Lysosomes handle hydrolysis, SER handles lipids, and Golgi modifies proteins.",
          sourceReference: "NCERT Biology Class 11 - Cell: The Unit of Life",
        };
        questions.push(shuffleQuestionOptions(baseQuestion));
      } else {
        // IMAT
        const baseQuestion: GeneratedQuestion = {
          questionText: `During human cardiac ventricular systole, which hemodynamic event occurs immediately after the closure of the atrioventricular valves? (Draft #${i} - ${request.subject})`,
          difficulty: request.difficulty,
          subject: request.subject,
          topic: request.topic,
          subtopic: request.subtopic,
          options: [
            {
              optionKey: "A",
              optionText: "Isovolumetric ventricular contraction",
              isCorrect: true,
            },
            { optionKey: "B", optionText: "Rapid ventricular filling phase", isCorrect: false },
            { optionKey: "C", optionText: "Atrial systole and atrial kick", isCorrect: false },
            {
              optionKey: "D",
              optionText: "Isovolumetric ventricular relaxation",
              isCorrect: false,
            },
            {
              optionKey: "E",
              optionText: "Closure of the aortic and pulmonary semilunar valves",
              isCorrect: false,
            },
          ],
          correctOptionKey: "A",
          explanation:
            "Immediately upon AV valve closure, all four cardiac valves are closed and ventricular pressure rises with constant volume (isovolumetric contraction) until semilunar valves open.",
          sourceReference: "IMAT Human Anatomy & Physiology - Cardiovascular Dynamics",
        };
        questions.push(shuffleQuestionOptions(baseQuestion));
      }
    }

    return {
      questions,
      provider: this.providerName,
      model: "mock-model-v1",
      usage: {
        promptTokens: 150 * count,
        completionTokens: 220 * count,
        totalTokens: 370 * count,
      },
      latencyMs: 45,
    };
  }
}
