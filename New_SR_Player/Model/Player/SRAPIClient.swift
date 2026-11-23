//
//  SRAPIClient.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-06.
//

import Foundation


// MARK: - Protocol (testability)

protocol SRAPIClientProtocol: Sendable {
    func fetchPrograms() async throws -> [SRProgram]
    func fetchPodFiles(programID: Int) async throws -> [SRPodFile]
}


struct SRAPIClient: SRAPIClientProtocol {

    private let base = "https://api.sr.se/api/v2"


    // MARK: - Programs (podcasts)

    func fetchPrograms() async throws -> [SRProgram] {
        let url = URL(string: "\(base)/programs/index?format=json&haspod=true&size=100")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRProgramsResponse.self, from: data)
        return response.programs
    }

    func fetchPodFiles(programID: Int) async throws -> [SRPodFile] {
        let url = URL(string: "\(base)/podfiles?programid=\(programID)&format=json&size=20")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SRPodFilesResponse.self, from: data)
        return response.podfiles
    }

}
