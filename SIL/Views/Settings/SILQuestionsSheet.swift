//
//  SILQuestionsSheet.swift
//  SIL
//
//  The questions people actually ask, answered in the app's own words.
//
//  The old copy described the RPG: hunters, ranks, death penalties, the Shop,
//  Neural Links, six stats. None of that is what the app says any more, so
//  the answers are rewritten rather than renamed. The old presentation — a
//  bare `DisclosureGroup` pushed into a `ScrollView`, which clipped its own
//  label off both edges — is replaced by a sheet of its own.
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

enum FAQCatalog {

    static let items: [FAQItem] = [
        FAQItem(
            question: "What is SIL?",
            answer: "A habit tracker that keeps score. You set the habits you want to hold, close them as you do them, and the app turns that into progress, credits you can spend on real rewards, and four attributes that grow — body, mind, energy and spirit."
        ),
        FAQItem(
            question: "What is progress, and what are levels?",
            answer: "Closing a habit earns progress, scaled to the effort you set on it. Enough progress takes you up a level. A run of good days multiplies what each habit pays."
        ),
        FAQItem(
            question: "How does a run work?",
            answer: "Close everything due on a day and your run grows by one. Longer runs pay more on every habit. A streak cover, bought from Rewards, carries a run through one missed day."
        ),
        FAQItem(
            question: "What happens when I miss a day?",
            answer: "Missed habits take momentum off the meter. If momentum runs out, SIL recalibrates: it resets the meter and, unless you've switched that off, eases your attributes back. A rest day, bought from Rewards, excuses a day in advance — no momentum lost, run intact."
        ),
        FAQItem(
            question: "Can I turn recalibration off?",
            answer: "Yes, in Settings, and in pieces: whether it drops a level, whether it eases your attributes, and whether it costs credits. Missed habits still cost momentum, but with all three off nothing is taken when the meter empties — it simply refills."
        ),
        FAQItem(
            question: "What are the four attributes?",
            answer: "Body, mind, energy and spirit. Each habit says which one it builds, and closing it grows that one. Movement builds body, study and focus build mind, sleep and food build energy, and the things you do deliberately — meditating, resisting a habit you're dropping — build spirit."
        ),
        FAQItem(
            question: "What is Focus?",
            answer: "A timer for one thing at a time. Set the length, say what it builds, and start. Leaving the app holds the clock rather than ending the session, and ending early pays for the minutes you actually sat down for."
        ),
        FAQItem(
            question: "What are credits for?",
            answer: "Rewards, on the You tab. Some are the app's own — a breather that puts momentum back, a streak cover, a rest day — and the rest are things in the real world. You can add your own and set what they cost."
        ),
        FAQItem(
            question: "Can habits close themselves?",
            answer: "Yes. A habit can read Apple Health, so steps, workouts, sleep and water close on their own, or it can watch a place, so being there long enough closes it. Both need permission, which you give in Settings and can take back at any time."
        ),
        FAQItem(
            question: "Does my progress sync between devices?",
            answer: "Yes. SIL keeps a copy in your private iCloud. Sign in with the same Apple ID and turn iCloud on, and each device picks up where the last one left off."
        ),
        FAQItem(
            question: "What does Reset do?",
            answer: "Clears everything you've built: habits, goals, progress, credits, momentum, runs and milestones all go back to the start. Your settings stay. It cannot be undone."
        )
    ]
}

/// The Questions sheet. One question open at a time, so the list stays
/// scannable.
struct SILQuestionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var openID: UUID?

    var body: some View {
        ZStack {
            S.bg2.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Questions")
                        .font(S.display(28, .semibold))
                        .tracking(S.displayTracking(28))
                        .foregroundStyle(S.ink)
                    Spacer()
                    SILRoundButton(systemImage: "xmark", size: 40) { dismiss() }
                }
                .padding(.top, 18)

                ScrollView {
                    SILListCard {
                        ForEach(Array(FAQCatalog.items.enumerated()), id: \.element.id) { index, item in
                            FAQRow(
                                item: item,
                                isOpen: openID == item.id,
                                showsDivider: index > 0
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    openID = openID == item.id ? nil : item.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 18)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
        }
        .presentationDragIndicator(.visible)
        .silAppearance()
    }
}

private struct FAQRow: View {
    let item: FAQItem
    let isOpen: Bool
    let showsDivider: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(item.question)
                    .font(S.text(16))
                    .foregroundStyle(S.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(S.ink3)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .padding(.top, 4)
            }

            if isOpen {
                Text(item.answer)
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .overlay(alignment: .top) {
            if showsDivider {
                Rectangle().fill(S.line).frame(height: 1)
            }
        }
    }
}

#Preview {
    SILQuestionsSheet()
}
