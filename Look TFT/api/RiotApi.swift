//
//  RiotApi.swift
//  Look TFT
//
//  Created by Lit Wa Yuen on 2/23/20.
//  Copyright © 2020 Lit Wa Yuen. All rights reserved.
//

import Foundation
class RiotApi: ObservableObject {
    @Published var summoner: SummonerDto!
    @Published var matchesDetail: [MatchDto] = []
    @Published var league: LeagueEntryDto!

    var leagues: [LeagueEntryDto] = []
    var matches: [String] = []
    
    func reset() {
        matches.removeAll()
        matchesDetail.removeAll()
        leagues.removeAll()
    }
    
    
    func fetchMatches(puuid: String)  {
        let route = regionMap[region]
        let apiUrl = "https://\(route!).api.riotgames.com/tft/match/v1/matches/by-puuid/\(puuid)/ids?count=20&api_key=\(API_KEY)"
        guard let url = URL(string: apiUrl) else { return }
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            DispatchQueue.main.async {
                self.matches = try! JSONDecoder().decode([String].self, from: data!)
                self.matches.forEach { (match) in
                    self.fetchMatch(matchId: match)
                }
            }
        }.resume()
    }
    
    func fetchSummonerLeague(id: String)  {
        let route = platformMap[region]
        let apiUrl = "https://\(route!).api.riotgames.com/tft/league/v1/entries/by-summoner/\(id)?api_key=\(API_KEY)"
        guard let url = URL(string: apiUrl) else { return }
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            DispatchQueue.main.async {
                self.leagues = try! JSONDecoder().decode([LeagueEntryDto].self, from: data!)
                self.league = self.leagues.first { (league) -> Bool in
                    league.queueType == "RANKED_TFT"
                }
                if self.league == nil {
                    self.league = LeagueEntryDto(queueType: "RANKED_TFT", rank: "I", tier: "provisional", leaguePoints: 0)
                }
            }
        }.resume()
    }
    
    func fetchMatch(matchId: String)  {
        let route = regionMap[region]
        reset()
        let apiUrl = "https://\(route!).api.riotgames.com/tft/match/v1/matches/\(matchId)?api_key=\(API_KEY)"
        guard let url = URL(string: apiUrl) else { return }
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            DispatchQueue.main.async {
                guard let httpResponse = resp as? HTTPURLResponse else {return }

                switch(httpResponse.statusCode) {
                case 200:
                    do {
                         var matchD = try JSONDecoder().decode(MatchDto.self, from: data!)
                        matchD.getSummonerInfo(self.summoner.puuid)
                        
                        self.matchesDetail.append(matchD)
                        self.matchesDetail.sort(by: { (m1:MatchDto, m2:MatchDto) -> Bool in
                            return m1.info.game_datetime > m2.info.game_datetime
                        })

                    } catch {
                        print("error")
                    }

                default:
                    print(httpResponse.statusCode)
                }

            }
        }.resume()
    }
    func fetchSummoner(name: String)  {
        let urlSummonerName: String = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let route = platformMap[region]
        let apiUrl = "https://\(route!).api.riotgames.com/tft/summoner/v1/summoners/by-name/\(urlSummonerName)?api_key=\(API_KEY)"
        guard let url = URL(string: apiUrl) else { return }
        URLSession.shared.dataTask(with: url) { (data, resp, err) in
            DispatchQueue.main.async {
                guard let httpResponse = resp as? HTTPURLResponse else {return }

                switch(httpResponse.statusCode) {
                case 200:
                    self.summoner = try! JSONDecoder().decode(SummonerDto.self, from: data!)
                    self.fetchSummonerLeague(id: self.summoner.id)
                    self.fetchMatches(puuid: self.summoner.puuid)
                default:
                    print(httpResponse.statusCode)
                
                }
                
            }
        }.resume()
    }
}
