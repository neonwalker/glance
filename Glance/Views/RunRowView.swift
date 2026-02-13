import SwiftUI

struct RunRowView: View {
    let run: WorkflowRun
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: run.status.icon)
                .font(.system(size: 16))
                .foregroundStyle(run.status.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.repo.fullName)
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Label(run.branch, systemImage: "arrow.branch")
                    Text("·")
                    Text(run.workflowName)
                    Text("·")
                    Text(run.timeAgo)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if !run.displayTitle.isEmpty {
                    Text(run.displayTitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(run.status.label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(run.status.color.opacity(0.15))
                .foregroundStyle(run.status.color)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if let url = URL(string: run.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
