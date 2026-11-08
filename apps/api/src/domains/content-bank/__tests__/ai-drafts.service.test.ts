import { describe, it, expect, beforeEach } from "vitest";
import { AIDraftsService, AuthContext, GenerateDraftsInput } from "../ai-drafts.service";
import { InMemoryAIDraftsRepository } from "../ai-drafts.repository";
import { MockQuestionProvider } from "../../../infrastructure/ai/mock-provider";

describe("AIDraftsService (Domain Service)", () => {
  let repository: InMemoryAIDraftsRepository;
  let mockProvider: MockQuestionProvider;
  let service: AIDraftsService;

  const facultyAuth: AuthContext = {
    userId: "usr-faculty-01",
    role: "FACULTY",
    institutionId: "inst-apex-medical",
  };

  const studentAuth: AuthContext = {
    userId: "usr-student-01",
    role: "STUDENT",
    institutionId: "inst-apex-medical",
  };

  const validNeetInput: GenerateDraftsInput = {
    examCode: "NEET_UG",
    examVersionId: "ver-neet-2026",
    sectionId: "sec-biology",
    syllabusNodeId: "node-cell-bio",
    subject: "Biology",
    topic: "Cell Structure and Function",
    difficulty: "MEDIUM",
    count: 2,
    languageCode: "en",
    examYear: 2026,
  };

  beforeEach(() => {
    repository = new InMemoryAIDraftsRepository();
    mockProvider = new MockQuestionProvider();
    service = new AIDraftsService(repository, mockProvider);
  });

  describe("Security & Access Control", () => {
    it("strictly forbids students from generating AI questions", async () => {
      await expect(service.generateQuestions(validNeetInput, studentAuth)).rejects.toThrow(
        /Access Denied: Only faculty and academic administrators/,
      );
    });

    it("allows faculty to initiate question draft generation", async () => {
      const result = await service.generateQuestions(validNeetInput, facultyAuth);
      expect(result.status).toBe("COMPLETED");
      expect(result.count).toBe(2);
      expect(result.drafts).toHaveLength(2);
    });
  });

  describe("Draft State & Human-in-the-Loop Queue", () => {
    it("creates questions in strictly DRAFT status and queues for review", async () => {
      const result = await service.generateQuestions(validNeetInput, facultyAuth);

      // Verify job record
      const job = await repository.getJobById(result.jobId);
      expect(job).toBeDefined();
      expect(job?.status).toBe("COMPLETED");
      expect(job?.institution_id).toBe("inst-apex-medical");

      // Verify each generated question is in DRAFT status
      for (const draft of result.drafts) {
        const question = repository.questions.get(draft.questionId);
        expect(question).toBeDefined();
        expect(question?.institution_id).toBe("inst-apex-medical");

        const version = repository.versions.get(draft.versionId);
        expect(version).toBeDefined();
        expect(version?.review_status).toBe("DRAFT"); // Mandatory requirement

        const review = await repository.getReviewById(draft.reviewId);
        expect(review).toBeDefined();
        expect(review?.review_status).toBe("PENDING");
        expect(review?.validation_status).toBe("PASSED");
      }
    });

    it("rejects batch count less than 1 or greater than 10", async () => {
      await expect(
        service.generateQuestions({ ...validNeetInput, count: 0 }, facultyAuth),
      ).rejects.toThrow(/Question generation count must be between 1 and 10/);

      await expect(
        service.generateQuestions({ ...validNeetInput, count: 11 }, facultyAuth),
      ).rejects.toThrow(/Question generation count must be between 1 and 10/);
    });
  });

  describe("Faculty Review Workflow", () => {
    it("approves a draft question and transitions review_status to APPROVED", async () => {
      const generateResult = await service.generateQuestions(
        { ...validNeetInput, count: 1 },
        facultyAuth,
      );
      const reviewId = generateResult.drafts[0].reviewId;

      const reviewResult = await service.reviewDraft(
        { reviewId, decision: "APPROVE" },
        facultyAuth,
      );

      expect(reviewResult.status).toBe("APPROVED");

      const review = await repository.getReviewById(reviewId);
      expect(review?.review_status).toBe("APPROVED");
      expect(review?.reviewed_by).toBe("usr-faculty-01");

      const version = repository.versions.get(generateResult.drafts[0].versionId);
      expect(version?.review_status).toBe("APPROVED");
    });

    it("approves with edits and transitions status to EDITED with updated fields", async () => {
      const generateResult = await service.generateQuestions(
        { ...validNeetInput, count: 1 },
        facultyAuth,
      );
      const reviewId = generateResult.drafts[0].reviewId;

      const reviewResult = await service.reviewDraft(
        {
          reviewId,
          decision: "APPROVE",
          edits: {
            questionText: "Faculty edited: Enhanced clinical stem text for clarity.",
            explanation: "Faculty edited: Added comprehensive enzymatic pathway reference.",
          },
        },
        facultyAuth,
      );

      expect(reviewResult.status).toBe("EDITED");

      const version = repository.versions.get(generateResult.drafts[0].versionId);
      expect(version?.question_text).toBe(
        "Faculty edited: Enhanced clinical stem text for clarity.",
      );
      expect(version?.review_status).toBe("APPROVED");
    });

    it("rejects a draft question and sets review_status to REJECTED", async () => {
      const generateResult = await service.generateQuestions(
        { ...validNeetInput, count: 1 },
        facultyAuth,
      );
      const reviewId = generateResult.drafts[0].reviewId;

      const reviewResult = await service.reviewDraft(
        {
          reviewId,
          decision: "REJECT",
          comments: "Ambiguous wording in distractor C",
        },
        facultyAuth,
      );

      expect(reviewResult.status).toBe("REJECTED");

      const review = await repository.getReviewById(reviewId);
      expect(review?.review_status).toBe("REJECTED");

      const version = repository.versions.get(generateResult.drafts[0].versionId);
      expect(version?.review_status).toBe("REJECTED");
    });

    it("prevents reviewing an already resolved review", async () => {
      const generateResult = await service.generateQuestions(
        { ...validNeetInput, count: 1 },
        facultyAuth,
      );
      const reviewId = generateResult.drafts[0].reviewId;

      await service.reviewDraft({ reviewId, decision: "APPROVE" }, facultyAuth);

      await expect(
        service.reviewDraft({ reviewId, decision: "APPROVE" }, facultyAuth),
      ).rejects.toThrow(/already been resolved/);
    });
  });

  describe("Institution Isolation", () => {
    it("prevents faculty from viewing jobs from another institution", async () => {
      const otherFacultyAuth: AuthContext = {
        userId: "usr-faculty-other",
        role: "FACULTY",
        institutionId: "inst-other-medical",
      };

      const result = await service.generateQuestions(validNeetInput, facultyAuth);

      await expect(service.getJobStatus(result.jobId, otherFacultyAuth)).rejects.toThrow(
        /Access denied: You cannot view jobs belonging to another institution/,
      );
    });
  });
});
