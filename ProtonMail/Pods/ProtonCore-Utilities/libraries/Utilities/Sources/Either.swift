//
//  Either.swift
//  ProtonCore-Utilities - Created on 16.03.22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

public enum Either<Left, Right> {
    case left(Left)
    case right(Right)
    
    public func mapLeft<T>(f: (Left) -> T) -> Either<T, Right> {
        switch self {
        case .left(let left): return .left(f(left))
        case .right(let right): return .right(right)
        }
    }
    
    public func mapRight<T>(f: (Right) -> T) -> Either<Left, T> {
        switch self {
        case .left(let left): return .left(left)
        case .right(let right): return .right(f(right))
        }
    }
    
    public func value() -> Left where Left == Right {
        switch self {
        case .left(let left): return left
        case .right(let right): return right
        }
    }
    
    public func sequence<T, S, E>() -> Result<Either<T, S>, E> where Left == Result<T, E>, Right == Result<S, E>, E: Error {
        switch self {
        case .left(.success(let t)): return .success(.left(t))
        case .right(.success(let s)): return .success(.right(s))
        case .left(.failure(let error)), .right(.failure(let error)): return .failure(error)
        }
    }
}
