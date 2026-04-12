export type ApiError = {
  code: string;
  message: string;
  details?: unknown;
};

export class AppError extends Error {
  code: string;
  statusCode: number;
  details?: unknown;

  constructor(message: string, code: string, statusCode: number, details?: unknown) {
    super(message);
    this.name = "AppError";
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
  }

  toJSON(): ApiError {
    return {
      code: this.code,
      message: this.message,
      ...(this.details !== undefined && { details: this.details }),
    };
  }
}

export class NotFoundError extends AppError {
  constructor(message = "Not found", details?: unknown) {
    super(message, "NOT_FOUND", 404, details);
    this.name = "NotFoundError";
  }
}

export class ForbiddenError extends AppError {
  constructor(message = "Forbidden", details?: unknown) {
    super(message, "FORBIDDEN", 403, details);
    this.name = "ForbiddenError";
  }
}

export class ValidationError extends AppError {
  constructor(message = "Validation failed", details?: unknown) {
    super(message, "VALIDATION_ERROR", 422, details);
    this.name = "ValidationError";
  }
}
