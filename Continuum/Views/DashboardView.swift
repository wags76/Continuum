import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject private var appNavigation: AppNavigation
    @Query private var subscriptions: [Subscription]
    @Query private var assets: [PersonalAsset]
    @Query private var warranties: [Warranty]
    @State private var showMonthlyBreakdown = false
    @State private var selectedSubscription: Subscription?
    @State private var selectedWarranty: Warranty?

    private var subscriptionMonthlyTotal: Decimal {
        subscriptions.filter(\.isSubscription).reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var recurringPaymentsMonthlyTotal: Decimal {
        subscriptions.filter { !$0.isSubscription }.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    private var monthlyRecurringTotal: Decimal {
        subscriptionMonthlyTotal + recurringPaymentsMonthlyTotal
    }

    private var totalAssetsValue: Decimal {
        assets.reduce(0) { $0 + $1.currentValue }
    }

    private var expiringWarranties: [Warranty] {
        let horizon = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return warranties
            .filter { !$0.isExpired && $0.expiryDate <= horizon }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var upcomingRenewals: [Subscription] {
        let horizon = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return subscriptions
            .filter { $0.nextDueDate <= horizon }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    private var attentionCount: Int {
        subscriptions.filter(\.isPastDue).count + expiringWarranties.count
    }

    private var hasAnyData: Bool {
        !subscriptions.isEmpty || !assets.isEmpty || !warranties.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    heroCard

                    if hasAnyData {
                        snapshotSection
                        attentionSection
                    } else {
                        gettingStartedCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(ContinuumStyle.canvas.ignoresSafeArea())
            .navigationTitle("Continuum")
            .navigationDestination(item: $selectedSubscription) { subscription in
                SubscriptionDetailView(subscription: subscription)
            }
            .navigationDestination(item: $selectedWarranty) { warranty in
                WarrantyDetailView(warranty: warranty)
            }
            .sheet(isPresented: $showMonthlyBreakdown) {
                MonthlyRecurringBreakdownSheet(
                    subscriptions: subscriptions,
                    total: monthlyRecurringTotal,
                    onViewAll: {
                        showMonthlyBreakdown = false
                        appNavigation.switchToItems(category: .subscriptions)
                    }
                )
            }
        }
    }

    private var heroCard: some View {
        Button {
            showMonthlyBreakdown = true
        } label: {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Label("MONTHLY COMMITMENTS", systemImage: "waveform.path.ecg")
                        .font(.caption.weight(.bold))
                        .tracking(0.6)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white.opacity(0.82))

                VStack(alignment: .leading, spacing: 4) {
                    Text(ContinuumFormatters.currency(monthlyRecurringTotal))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                    Text(subscriptions.isEmpty ? "Add recurring items to see your monthly baseline" : "Estimated across all recurring items")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }

                HStack(spacing: 8) {
                    heroPill("\(subscriptions.filter(\.isSubscription).count) subscriptions", icon: "creditcard")
                    heroPill("\(subscriptions.filter { !$0.isSubscription }.count) payments", icon: "repeat")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .foregroundStyle(.white)
            .background {
                ZStack {
                    LinearGradient(
                        colors: [Color.accentColor, Color.indigo.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 190)
                        .offset(x: 150, y: -70)
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 120)
                        .offset(x: 80, y: 100)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .shadow(color: Color.accentColor.opacity(0.25), radius: 20, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows the monthly recurring cost breakdown")
    }

    private func heroPill(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.14), in: Capsule())
    }

    private var snapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Your snapshot", subtitle: "A quick read on what you track")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                SnapshotCard(
                    title: "Assets",
                    value: ContinuumFormatters.currency(totalAssetsValue),
                    detail: "\(assets.count) tracked",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                ) { appNavigation.switchToItems(category: .assets) }

                SnapshotCard(
                    title: "Warranties",
                    value: "\(warranties.count)",
                    detail: expiringWarranties.isEmpty ? "All clear" : "\(expiringWarranties.count) expiring soon",
                    icon: "shield.checkered",
                    color: .purple
                ) { appNavigation.switchToItems(category: .warranties) }

                SnapshotCard(
                    title: "Subscriptions",
                    value: ContinuumFormatters.currency(subscriptionMonthlyTotal),
                    detail: "per month",
                    icon: "creditcard",
                    color: .orange
                ) { appNavigation.switchToItems(category: .subscriptions) }

                SnapshotCard(
                    title: "Other payments",
                    value: ContinuumFormatters.currency(recurringPaymentsMonthlyTotal),
                    detail: "per month",
                    icon: "repeat",
                    color: .teal
                ) { appNavigation.switchToItems(category: .recurringPayments) }
            }
        }
    }

    @ViewBuilder
    private var attentionSection: some View {
        if !upcomingRenewals.isEmpty || !expiringWarranties.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading(
                    "Needs attention",
                    subtitle: attentionCount == 0 ? "Coming up in the next 30 days" : "\(attentionCount) item\(attentionCount == 1 ? "" : "s") to review"
                )

                VStack(spacing: 0) {
                    ForEach(Array(upcomingRenewals.prefix(4).enumerated()), id: \.element.persistentModelID) { index, subscription in
                        Button {
                            selectedSubscription = subscription
                        } label: {
                            AttentionRow(
                                title: subscription.name,
                                detail: subscription.isPastDue ? "Past due" : subscription.nextDueDate.formatted(.dateTime.month(.abbreviated).day()),
                                value: ContinuumFormatters.currency(subscription.amount),
                                icon: subscription.isSubscription ? "creditcard.fill" : "repeat",
                                color: subscription.isPastDue ? .red : .orange
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens subscription details")
                        if index < min(upcomingRenewals.count, 4) - 1 || !expiringWarranties.isEmpty { Divider().padding(.leading, 52) }
                    }

                    ForEach(Array(expiringWarranties.prefix(3).enumerated()), id: \.element.persistentModelID) { index, warranty in
                        Button {
                            selectedWarranty = warranty
                        } label: {
                            AttentionRow(
                                title: warranty.productName,
                                detail: warranty.expiryDate.formatted(.dateTime.month(.abbreviated).day().year()),
                                value: "\(max(warranty.daysUntilExpiry, 0))d left",
                                icon: "shield.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens warranty details")
                        if index < min(expiringWarranties.count, 3) - 1 { Divider().padding(.leading, 52) }
                    }
                }
                .continuumCard(padding: 14)
            }
        }
    }

    private var gettingStartedCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ContinuumSymbolTile(systemImage: "sparkles", color: .indigo, size: 48)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Build your financial timeline")
                        .font(.title3.weight(.bold))
                    Text("Start with one item. Continuum will organize costs, due dates, values, and coverage for you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 10) {
                startButton("Add a subscription", icon: "creditcard", category: .subscriptions, color: .orange)
                startButton("Track an asset", icon: "chart.line.uptrend.xyaxis", category: .assets, color: .green)
                startButton("Add a warranty", icon: "shield.checkered", category: .warranties, color: .purple)
            }
        }
        .continuumCard()
    }

    private func startButton(_ title: String, icon: String, category: ItemCategory, color: Color) -> some View {
        Button {
            appNavigation.switchToItems(category: category)
        } label: {
            HStack(spacing: 12) {
                ContinuumSymbolTile(systemImage: icon, color: color, size: 36)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color(.tertiarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SnapshotCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ContinuumSymbolTile(systemImage: icon, color: color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(value)
                        .font(.title3.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .continuumCard(padding: 15)
        }
        .buttonStyle(.plain)
    }
}

private struct AttentionRow: View {
    let title: String
    let detail: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ContinuumSymbolTile(systemImage: icon, color: color, size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(color == .red ? .red : .secondary)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

private struct MonthlyRecurringBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss
    let subscriptions: [Subscription]
    let total: Decimal
    let onViewAll: () -> Void

    private var subscriptionItems: [Subscription] {
        subscriptions.filter(\.isSubscription).sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
    }

    private var recurringItems: [Subscription] {
        subscriptions.filter { !$0.isSubscription }.sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Monthly estimate") {
                    LabeledContent("Total", value: ContinuumFormatters.currency(total))
                        .font(.headline)
                }
                breakdownSection("Subscriptions", items: subscriptionItems)
                breakdownSection("Recurring payments", items: recurringItems)
            }
            .navigationTitle("Monthly commitments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                if !subscriptions.isEmpty {
                    ToolbarItem(placement: .primaryAction) { Button("View all", action: onViewAll) }
                }
            }
        }
    }

    @ViewBuilder
    private func breakdownSection(_ title: String, items: [Subscription]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { item in
                    LabeledContent(item.name, value: ContinuumFormatters.currency(item.monthlyEquivalent))
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppNavigation())
        .modelContainer(for: [Subscription.self, PersonalAsset.self, AssetValueChange.self, Warranty.self], inMemory: true)
}
