//
//  FlickrResults.swift
//  Virtual_Tourist_01
//
//  Created by Giordany Orellana on 4/29/19.
//  Copyright © 2019 Giordany Orellana. All rights reserved.
//

import Foundation

enum Result<ResultType> {
    case results(ResultType)
    case error(Error)
}
