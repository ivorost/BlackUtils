//
//  File.swift
//  
//
//  Created by Ivan Kh on 28.04.2023.
//

import Foundation

@inlinable public func withTaskGroupContinuation<ChildTaskResult, GroupResult>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    body: @escaping (_ continuation: CheckedContinuation<GroupResult, Never>,
                     _ group: inout TaskGroup<ChildTaskResult>) async -> Void
) async -> GroupResult where ChildTaskResult : Sendable {
    await withCheckedContinuation { continuation in
        Task {
            await withTaskGroup(of: childTaskResultType) { group in
                await body(continuation, &group)
            }
        }
    }
}

@inlinable public func withThrowingTaskGroupContinuation<ChildTaskResult, GroupResult>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    body: @escaping (_ continuation: CheckedContinuation<GroupResult, Error>,
                     _ group: inout ThrowingTaskGroup<ChildTaskResult, Error>) async throws -> Void
) async throws -> GroupResult where ChildTaskResult : Sendable {
    try await withCheckedThrowingContinuation { continuation in
        Task {
            try await withThrowingTaskGroup(of: childTaskResultType) { group in
                try await body(continuation, &group)
            }
        }
    }
}
