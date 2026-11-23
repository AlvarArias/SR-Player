# SwiftUI View Builder

Build a new SwiftUI view following the project's MVVM pattern.

## Steps

1. **Create `New_SR_Player/Views/{ViewName}.swift`** containing:
   - Model struct(s) — `Identifiable` if used in lists
   - `{ViewName}ViewModel: ObservableObject` — `@Published` state + business logic, marked `@MainActor`
   - Sub-view components as `private struct`
   - Main `{ViewName}: View`
   - `{ViewName}_Previews: PreviewProvider`

2. **Create `New_SR_PlayerTests/{ViewName}ViewModelTests.swift`** with:
   - At least one test per public method on the ViewModel
   - `@MainActor` on the test class if the ViewModel is `@MainActor`
   - No network or Firebase calls — mock or pure logic only

3. **Add the new view to `CLAUDE.md`**:
   - Architecture diagram (mermaid)
   - File structure section
   - Tests table

4. **Update `progress.txt`** — move the task from Pending/In Progress → Done.

## Conventions

- No comments unless the WHY is non-obvious
- `private` for all sub-view structs in the same file
- `@StateObject` to own a ViewModel; `@ObservedObject` to receive one
- Use `Color` extensions from `Colors.swift` for the palette (`brown_light_p1`, `gray_light_p2`, `gray_p3`, `green_light_p4`, `green_p5`, `orange_light_p6`, `red_dark_p6`)
- All `@Published` mutations must happen on `@MainActor`
- Match the visual style of the reference design: grouped background, rounded cards, colored thumbnails
