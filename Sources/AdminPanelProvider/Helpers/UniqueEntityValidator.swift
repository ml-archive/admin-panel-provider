import Fluent
import Forms
import Validation

internal final class UniqueEntityValidator: Validator {
    typealias CountEntities = (
        _ fieldName: String,
        _ value: String,
        _ exceptId: Identifier?
        ) throws -> Int

    private let fieldName: String
    private let exceptId: Identifier?
    private let countOfEntities: CountEntities
    private let errorOnExist: FormFieldValidationError

    internal init(
        fieldName: String,
        exceptId: Identifier?,
        countOfEntities: @escaping CountEntities,
        errorOnExist: FormFieldValidationError
    ) {
        self.countOfEntities = countOfEntities
        self.errorOnExist = errorOnExist
        self.exceptId = exceptId
        self.fieldName = fieldName
    }

    internal func validate(_ input: String) throws {
        guard try countOfEntities(fieldName, input, exceptId) == 0 else {
            throw errorOnExist
        }
    }
}

extension Entity {
    static func countOfEntities(
        where fieldName: String,
        equals input: String,
        exceptId: Identifier?
    ) throws -> Int {
        return try makeQuery()
            .filter(fieldName, input)
            .filter(idKey, .notEquals, exceptId)
            .count()
    }
}
