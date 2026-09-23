from pathlib import Path


MIGRATIONS = Path(__file__).parents[1] / "supabase" / "migrations"


def test_return_tracking_function_has_a_valid_rejection_reason_default() -> None:
    sql = (MIGRATIONS / "202609080009_add_return_tracking.sql").read_text()

    assert "p_rejection_reason text default ''" in sql
    assert "need this money" not in sql


def test_environment_example_contains_placeholders_only() -> None:
    content = (Path(__file__).parents[1] / ".env.example").read_text()

    assert "https://your-project-ref.supabase.co" in content
    assert "your-server-only-service-role-key" in content
