//
//  ContentView.swift
//  Look TFT
//
//  Created by Lit Wa Yuen on 2/23/20.
//  Copyright © 2020 Lit Wa Yuen. All rights reserved.
//

import SwiftUI
import Combine
import GoogleMobileAds

struct ContentView : View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var riotApi = RiotApi()
    @State private var name: String = ""
    @FetchRequest(
        entity: Summoner.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Summoner.name, ascending: false)]
    ) var mySummoner: FetchedResults<Summoner>


    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                TextField("Enter Summoner Name", text: $name) {
                    UIApplication.shared.endEditing()
                    }
                    .multilineTextAlignment(.center)
                    .padding(.init(top: 10, leading: 0, bottom: 0, trailing: 0))
                if riotApi.league != nil {
                    HStack(alignment: .center) {
                        Button(action: {
                            print("enter data core")
                        }) {
                            HStack {
                                Image("full heart")
                            }
                        }.hidden()
                        Spacer()
                        Image(riotApi.league.tier)
                        .resizable()
                        .frame(width: 50, height: 50)

                        if riotApi.league.tier != "provisional" {
                            if riotApi.league.tier == "MASTER" || riotApi.league.tier == "CHALLENGER"
                                || riotApi.league.tier == "GRANDMASTER" {
                                Text("\(riotApi.league.tier) \(riotApi.league.leaguePoints)")
                                .bold()
                            }
                            else {
                                Text("\(riotApi.league.tier) \(riotApi.league.rank) \(riotApi.league.leaguePoints)")
                                .bold()
                            }
                        }
                        Spacer()
                        Button(action: {
                            self.saveSummoner()
                        }) {
                            HStack {
                                if isSummoner() {
                                    Image("full star")
                                }
                                else {
                                    Image("star-outline")

                                }
                            }
                        }
                        
                    }.padding(.init(top: 0, leading: 15, bottom: 0, trailing: 15))
                }
               
                List{
                    ForEach(riotApi.matchesDetail, id: \.metadata.match_id) { match  in
                        MatchRowView(match: match)
                    }
                }.onAppear { UITableView.appearance().separatorStyle = .none }
                BannerViewController().frame(width: 320, height: 50, alignment: .center)

        
            }.navigationBarTitle(Text("Summoner: \(region.uppercased())"), displayMode: .inline)
            .navigationBarItems(
                leading: NavigationLink(destination: SettingsView()) {
                    Image("Settings")
                },
                trailing: Button(action: {
                    UIApplication.shared.endEditing()
                    self.riotApi.fetchSummoner(name: self.name)
                }) {
                    HStack {
                        Text("Search")
                    }
                }
            )
        }
    }
    
    func saveSummoner() {
        if isSummoner() {
            moc.delete(mySummoner.first!)
        }
        else {
            if mySummoner.first != nil {
                moc.delete(mySummoner.first!)
            }
            let me: Summoner = Summoner(context: moc)
            me.accountId = riotApi.summoner.accountId
            me.id = riotApi.summoner.id
            me.name = riotApi.summoner.name
            me.puuid = riotApi.summoner.puuid
            me.region = region
            do {
                try moc.save()
            } catch {
                print("error")
            }
        }
    
    }
    
    func isSummoner() -> Bool{
        let temp = mySummoner.first { (sum) -> Bool in
            sum.puuid == riotApi.summoner.puuid && sum.region == region
        }
        return temp != nil ? true : false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
