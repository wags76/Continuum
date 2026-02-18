//
//  CalendarView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/18/26.
//

import SwiftUI
import SwiftData
import UIKit

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]
    @Query(sort: \Warranty.expiryDate) private var warranties: [Warranty]

    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var selectedSubscription: Subscription?
    @State private var selectedWarranty: Warranty?

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                VStack(spacing: 0) {
                    headerSection
                    calendarContent
                        .padding(.horizontal)
                    selectedDayEvents
                        .padding(.top, 16)
                        .frame(maxHeight: .infinity)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewMode = viewMode == .month ? .week : .month
                        }
                    } label: {
                        Image(systemName: viewMode == .month ? "calendar" : "calendar.badge.clock")
                            .font(.title2)
                    }
                }
            }
            .navigationDestination(item: $selectedWarranty) { warranty in
                WarrantyDetailView(warranty: warranty)
            }
            .navigationDestination(item: $selectedSubscription) { subscription in
                SubscriptionDetailView(subscription: subscription)
            }
        }
    }

    private var headerSection: some View {
        Group {
            if viewMode == .month {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: previousPeriod) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.themeColor)
                                        .shadow(color: Color.themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                let today = Date()
                                currentMonth = today
                                selectedDate = today
                            }
                        } label: {
                            Text(periodTitle)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.themeColor.opacity(0.08))
                                        .overlay(Capsule().stroke(Color.themeColor.opacity(0.2), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: nextPeriod) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.themeColor)
                                        .shadow(color: Color.themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
            } else {
                HStack {
                    Button(action: previousPeriod) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.themeColor)
                                    .shadow(color: Color.themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            let today = Date()
                            currentMonth = today
                            selectedDate = today
                        }
                    } label: {
                        Text(periodTitle)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.themeColor.opacity(0.08))
                                    .overlay(Capsule().stroke(Color.themeColor.opacity(0.2), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: nextPeriod) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.themeColor)
                                    .shadow(color: Color.themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
                .background(Color(.systemGroupedBackground))
            }
        }
    }

    private var calendarContent: some View {
        Group {
            switch viewMode {
            case .month:
                MonthCalendarView(
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    subscriptions: subscriptions,
                    warranties: warranties,
                    onDateTap: handleDateTap
                )
            case .week:
                WeekCalendarView(
                    currentWeek: currentMonth,
                    selectedDate: $selectedDate,
                    subscriptions: subscriptions,
                    warranties: warranties,
                    onDateTap: handleDateTap
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    guard abs(value.translation.width) > threshold else { return }
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    if value.translation.width > 0 {
                        previousPeriod()
                    } else {
                        nextPeriod()
                    }
                }
        )
    }

    private var selectedDayEvents: some View {
        VStack(spacing: 0) {
            selectedDateHeader

            if subscriptionsForSelectedDate.isEmpty && warrantiesForSelectedDate.isEmpty {
                Spacer()
                EmptyDayView()
                    .padding(.horizontal)
                Spacer()
            } else {
                Spacer().frame(height: 16)
                List {
                    ForEach(subscriptionsForSelectedDate) { subscription in
                        Button {
                            selectedSubscription = subscription
                        } label: {
                            SubscriptionCalendarCard(subscription: subscription)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                        .buttonStyle(.plain)
                    }

                    ForEach(warrantiesForSelectedDate) { warranty in
                        Button {
                            selectedWarranty = warranty
                        } label: {
                            WarrantyCalendarCard(warranty: warranty)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var selectedDateHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.themeColor.opacity(0.1))
                        .frame(width: 28, height: 28)
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.themeColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Selected Date")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(selectedDate, style: .date)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                let totalEvents = subscriptionsForSelectedDate.count + warrantiesForSelectedDate.count
                if totalEvents > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.themeColor)
                        Text("\(totalEvents)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.themeColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.themeColor.opacity(0.1))
                            .overlay(Capsule().stroke(Color.themeColor.opacity(0.2), lineWidth: 1))
                    )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("No events")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.quaternarySystemFill)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.themeColor.opacity(0.03), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }

    private var periodTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .week:
            let weekStart = weekStartDate(for: currentMonth)
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: weekStart)
            formatter.dateFormat = "d, yyyy"
            let endString = formatter.string(from: weekEnd)
            return "\(startString) - \(endString)"
        }
        return formatter.string(from: currentMonth)
    }

    private var subscriptionsForSelectedDate: [Subscription] {
        subscriptions.filter { calendar.isDate($0.nextDueDate, inSameDayAs: selectedDate) }
    }

    private var warrantiesForSelectedDate: [Warranty] {
        warranties.filter { calendar.isDate($0.expiryDate, inSameDayAs: selectedDate) }
    }

    private func previousPeriod() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch viewMode {
            case .month:
                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            case .week:
                currentMonth = calendar.date(byAdding: .weekOfYear, value: -1, to: currentMonth) ?? currentMonth
            }
        }
    }

    private func nextPeriod() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch viewMode {
            case .month:
                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            case .week:
                currentMonth = calendar.date(byAdding: .weekOfYear, value: 1, to: currentMonth) ?? currentMonth
            }
        }
    }

    private func weekStartDate(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private func handleDateTap(_ date: Date) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = date
            switch viewMode {
            case .month:
                if !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                    currentMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
                }
            case .week:
                let weekStart = weekStartDate(for: date)
                let currentWeekStart = weekStartDate(for: currentMonth)
                if !calendar.isDate(weekStart, inSameDayAs: currentWeekStart) {
                    currentMonth = weekStart
                }
            }
        }
    }
}

// MARK: - Calendar View Modes

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case week = "Week"
}

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let subscriptions: [Subscription]
    let warranties: [Warranty]
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemBackground)))
                }
            }
            .padding(.bottom, 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date {
                        ContinuumCalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            subscriptions: subscriptionsForDate(date),
                            warranties: warrantiesForDate(date),
                            onTap: { onDateTap(date) },
                            isCompact: true
                        )
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var calendarDays: [Date?] {
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfCalendar = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start ?? monthStart
        let endOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.end ?? monthStart
        let endOfCalendar = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth

        var days: [Date?] = []
        var currentDate = startOfCalendar
        while currentDate < endOfCalendar {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return days
    }

    private func subscriptionsForDate(_ date: Date) -> [Subscription] {
        subscriptions.filter { calendar.isDate($0.nextDueDate, inSameDayAs: date) }
    }

    private func warrantiesForDate(_ date: Date) -> [Warranty] {
        warranties.filter { calendar.isDate($0.expiryDate, inSameDayAs: date) }
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    let currentWeek: Date
    @Binding var selectedDate: Date
    let subscriptions: [Subscription]
    let warranties: [Warranty]
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    VStack(spacing: 6) {
                        Text(dayName(for: date))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.themeColor : .secondary)
                            .frame(maxWidth: .infinity)
                        ContinuumCalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: true,
                            subscriptions: subscriptionsForDate(date),
                            warranties: warrantiesForDate(date),
                            onTap: { onDateTap(date) },
                            isCompact: false
                        )
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var weekDays: [Date] {
        let weekStart = weekStartDate(for: currentWeek)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func weekStartDate(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private func subscriptionsForDate(_ date: Date) -> [Subscription] {
        subscriptions.filter { calendar.isDate($0.nextDueDate, inSameDayAs: date) }
    }

    private func warrantiesForDate(_ date: Date) -> [Warranty] {
        warranties.filter { calendar.isDate($0.expiryDate, inSameDayAs: date) }
    }
}

// MARK: - Calendar Day View

struct ContinuumCalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let subscriptions: [Subscription]
    let warranties: [Warranty]
    let onTap: () -> Void
    let isCompact: Bool

    private let calendar = Calendar.current

    private var textColor: Color {
        if isSelected { return .white }
        if isCurrentMonth { return .primary }
        return .secondary.opacity(0.5)
    }

    private var backgroundColor: Color {
        if isSelected || calendar.isDateInToday(date) { return Color.clear }
        return Color(.tertiarySystemFill).opacity(0.3)
    }

    private var borderColor: Color {
        if isSelected { return Color.themeColor.opacity(0.3) }
        if calendar.isDateInToday(date) { return Color.themeColor.opacity(0.4) }
        return Color.clear
    }

    private var isToday: Bool { calendar.isDateInToday(date) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: isCompact ? 1 : 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: isCompact ? (isSelected ? 15 : 14) : (isSelected ? 18 : 16), weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(textColor)

                HStack(spacing: isCompact ? 2 : 3) {
                    ForEach(Array(subscriptions.prefix(2))) { sub in
                        Capsule()
                            .fill(sub.isPastDue ? .red : Color.themeColor)
                            .frame(width: isCompact ? (isSelected ? 8 : 6) : (isSelected ? 10 : 8), height: isCompact ? (isSelected ? 3 : 2.5) : (isSelected ? 5 : 4))
                    }
                    ForEach(Array(warranties.prefix(2))) { warranty in
                        Capsule()
                            .fill(warranty.isExpired ? .red : .purple)
                            .frame(width: isCompact ? (isSelected ? 8 : 6) : (isSelected ? 10 : 8), height: isCompact ? (isSelected ? 3 : 2.5) : (isSelected ? 5 : 4))
                    }
                    if subscriptions.count + warranties.count > 4 {
                        Circle()
                            .fill(.secondary.opacity(isSelected ? 0.8 : 0.5))
                            .frame(width: isCompact ? 2.5 : 3, height: isCompact ? 2.5 : 3)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: isCompact ? 36 : 52)
            .padding(.vertical, isCompact ? 2 : 6)
            .contentShape(Rectangle())
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(backgroundColor)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.themeColor, Color.themeColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    if isToday && !isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.themeColor.opacity(0.12), Color.themeColor.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: isSelected ? 2.5 : (isToday ? 1.5 : 0)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subscription Calendar Card

struct SubscriptionCalendarCard: View {
    let subscription: Subscription

    private var eventColor: Color {
        subscription.isPastDue ? .red : Color.themeColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(eventColor)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subscription.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatCurrency(subscription.amount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: subscription.isPastDue ? "exclamationmark.circle.fill" : "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text(subscription.isPastDue ? "Past due" : "Renewal")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(eventColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(eventColor.opacity(0.1)))
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(eventColor.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Warranty Calendar Card

struct WarrantyCalendarCard: View {
    let warranty: Warranty

    private var eventColor: Color {
        if warranty.isExpired { return .red }
        if warranty.daysUntilExpiry <= 30 { return .orange }
        return .purple
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(eventColor)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(warranty.productName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(warranty.vendor)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: warranty.isExpired ? "exclamationmark.triangle.fill" : "shield.checkered")
                    .font(.caption)
                Text(warranty.isExpired ? "Expired" : "Expires")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(eventColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(eventColor.opacity(0.1)))
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(eventColor.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Empty Day View

struct EmptyDayView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.themeColor.opacity(0.08))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.themeColor.opacity(0.2), lineWidth: 1))
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color.themeColor)
            }
            VStack(spacing: 12) {
                Text("No Renewals or Expirations")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("No subscriptions or warranties are due on this date. Switch to the Items tab to add or edit.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.primary.opacity(0.1), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
