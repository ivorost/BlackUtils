//
//  Swift.Struct.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public class StructContainer<T> {
    public let inner: T
    
    public init(_ inner: T) {
        self.inner = inner
    }
}
