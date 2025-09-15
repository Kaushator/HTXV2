# Pull Request Template

## Summary
Brief description of the changes in this PR.

## Type of Change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🧹 Code cleanup/refactoring
- [ ] 🔧 DevContainer/Infrastructure changes
- [ ] 🤖 AI/ML improvements

## Component(s) Modified
- [ ] Backend API
- [ ] Frontend UI
- [ ] MCP Service
- [ ] Database/Redis
- [ ] DevContainer
- [ ] AI/ML Tools
- [ ] Infrastructure (Docker/GCP)
- [ ] Documentation

## Changes Made
<!-- Describe the specific changes in detail -->

### Backend Changes
- 

### Frontend Changes
- 

### Infrastructure Changes
- 

### Documentation Changes
- 

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] API endpoints tested (include curl commands or screenshots)
- [ ] UI changes tested (include screenshots)

### Test Evidence
<!-- Include screenshots, curl outputs, test results -->

## Database Changes
- [ ] No database changes
- [ ] New migrations added
- [ ] Existing data migration required
- [ ] Schema changes are backward compatible

If migrations are included:
```sql
-- Include key migration commands here
```

## Configuration Changes
- [ ] No configuration changes
- [ ] New environment variables added (document in .env.example)
- [ ] Configuration files modified
- [ ] External service integrations updated

### New Environment Variables
```bash
# Add any new environment variables here
NEW_VAR=description_of_purpose
```

## Deployment Considerations
- [ ] No special deployment steps required
- [ ] Requires environment variable updates
- [ ] Requires database migration
- [ ] Requires infrastructure changes
- [ ] Requires dependency updates

### Rollback Plan
<!-- How to rollback if something goes wrong -->

## AI Usage Declaration
- [ ] No AI assistance used
- [ ] GitHub Copilot used for code completion
- [ ] AI used for documentation/comments
- [ ] AI used for debugging assistance
- [ ] AI used for architecture decisions

If AI was used, describe how and validate the generated code:
<!-- Explain AI usage and verification steps -->

## Checklist
- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Related Issues
<!-- Link to related issues -->
Closes #
Relates to #

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Additional Notes
<!-- Any additional information that reviewers should know -->