# Development Rules & Guidelines

## Core Integration Principles

### 1. Code Reuse First Policy
- **ALWAYS** analyze existing codebase before creating new components
- Identify reusable functions, classes, and patterns in current implementation
- Extend existing services rather than creating duplicate functionality
- Maintain consistency with established architecture patterns

### 2. Seamless Integration Requirements
- New code MUST integrate with existing Flutter project structure
- Follow established naming conventions and file organization
- Respect existing dependency management and imports
- Ensure compatibility with current Firebase/Cloudinary configurations

### 3. Error Prevention Strategy
- Test integration points before implementation
- Validate existing service connections (Firebase, Cloudinary)
- Maintain backward compatibility with current features
- Use existing error handling patterns and logging mechanisms

## Task Management Protocol

### 4. Task Execution Workflow
- Reference `tasks.md` file for current task priorities and requirements
- Mark tasks as IN_PROGRESS when starting implementation
- Update task status to COMPLETED when finished with verification
- Document any blockers or dependencies discovered during execution

### 5. Change Documentation Requirements
- **MANDATORY**: Update `D:\Freelance\GigWorkExp\Job-app\atulDocs\CHANGES.md` for ALL modifications
- Include:
  - File paths and line numbers changed
  - Before/After code snippets for significant changes
  - Purpose and impact of each modification
  - Integration points affected
  - Testing/verification performed

### 6. Documentation Format
```markdown
## [Date] - [Task Name]
### Changes Made:
**File**: `path/to/file`
- **Change**: Brief description
- **Integration**: How it connects to existing code
- **Status**: ✅ COMPLETED / ⚠️ IN_PROGRESS / ❌ BLOCKED
```

## Implementation Standards

### 7. Code Quality Gates
- Leverage existing utility functions and services
- Follow current project's state management patterns
- Maintain existing UI/UX consistency
- Preserve current performance optimizations

### 8. Integration Verification
- Verify builds successfully after changes
- Test affected user flows end-to-end
- Confirm existing features remain functional
- Validate environment configurations still work

## Enforcement
- These rules apply to ALL development activities
- No exceptions without explicit documentation of reasoning
- Regular review of adherence during task completion
- Continuous improvement of integration practices

**Last Updated**: December 19, 2024
**Status**: ACTIVE - All development must follow these guidelines