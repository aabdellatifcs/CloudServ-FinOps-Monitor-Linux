"""
OCI FinOps Monitor
-------------------
A Streamlit dashboard for monitoring Oracle Cloud Infrastructure (OCI) spend
and surfacing cost-saving recommendations.

Linux edition - functionally identical to the Windows VM build, packaged
for deployment on a Linux host (systemd service, venv-based install).
"""

import streamlit as st
import pandas as pd
from datetime import datetime, timedelta

from oci_finops import (
    get_oci_config,
    fetch_cost_summary,
    fetch_daily_cost_trend,
    fetch_cost_by_service,
    fetch_cost_by_compartment,
    generate_recommendations,
)

st.set_page_config(
    page_title="OCI FinOps Monitor",
    page_icon="💰",
    layout="wide",
)

# --------------------------------------------------------------------------
# Sidebar - connection & filter controls
# --------------------------------------------------------------------------
st.sidebar.title("OCI FinOps Monitor")
st.sidebar.caption("Cloud spend monitoring & cost optimization")

profile_name = st.sidebar.text_input("OCI CLI Profile", value="DEFAULT")
lookback_days = st.sidebar.slider("Lookback window (days)", 7, 90, 30)
refresh = st.sidebar.button("🔄 Refresh data")

st.sidebar.markdown("---")
st.sidebar.caption(
    "Reads OCI config from `~/.oci/config` (standard on Linux/macOS). "
    "Requires an OCI API signing key with USAGE_REPORT read access."
)

# --------------------------------------------------------------------------
# Load config & data
# --------------------------------------------------------------------------
try:
    config, tenancy_id = get_oci_config(profile_name)
except Exception as e:
    st.error(f"Could not load OCI config profile '{profile_name}': {e}")
    st.info(
        "Set up your CLI config first: `oci setup config` "
        "(see README.md for Linux install steps)."
    )
    st.stop()

end_date = datetime.utcnow()
start_date = end_date - timedelta(days=lookback_days)

with st.spinner("Fetching cost data from OCI..."):
    try:
        summary = fetch_cost_summary(config, tenancy_id, start_date, end_date)
        daily_trend = fetch_daily_cost_trend(config, tenancy_id, start_date, end_date)
        by_service = fetch_cost_by_service(config, tenancy_id, start_date, end_date)
        by_compartment = fetch_cost_by_compartment(config, tenancy_id, start_date, end_date)
        recommendations = generate_recommendations(config, tenancy_id)
    except Exception as e:
        st.error(f"Error fetching data from OCI: {e}")
        st.stop()

# --------------------------------------------------------------------------
# Top-line metrics
# --------------------------------------------------------------------------
st.title("💰 OCI FinOps Monitor")
st.caption(f"Tenancy spend overview · last {lookback_days} days")

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Spend", f"${summary['total_cost']:,.2f}")
col2.metric("Daily Average", f"${summary['avg_daily_cost']:,.2f}")
col3.metric(
    "Month-over-Month",
    f"{summary['mom_change_pct']:+.1f}%",
    delta=f"{summary['mom_change_pct']:+.1f}%",
)
col4.metric("Potential Savings", f"${summary['potential_savings']:,.2f}")

st.markdown("---")

# --------------------------------------------------------------------------
# Trend chart
# --------------------------------------------------------------------------
st.subheader("Daily Spend Trend")
st.line_chart(daily_trend.set_index("date")["cost"])

# --------------------------------------------------------------------------
# Breakdown charts
# --------------------------------------------------------------------------
bc1, bc2 = st.columns(2)

with bc1:
    st.subheader("Spend by Service")
    st.bar_chart(by_service.set_index("service")["cost"])

with bc2:
    st.subheader("Spend by Compartment")
    st.bar_chart(by_compartment.set_index("compartment")["cost"])

st.markdown("---")

# --------------------------------------------------------------------------
# Cost-saving recommendations
# --------------------------------------------------------------------------
st.subheader("💡 Cost-Saving Recommendations")

if recommendations.empty:
    st.success("No immediate cost-saving opportunities detected.")
else:
    total_potential = recommendations["est_monthly_savings"].sum()
    st.info(f"Estimated total potential monthly savings: **${total_potential:,.2f}**")

    for _, rec in recommendations.iterrows():
        severity_icon = {"high": "🔴", "medium": "🟡", "low": "🟢"}.get(
            rec["severity"], "⚪"
        )
        with st.expander(
            f"{severity_icon} {rec['title']} — est. ${rec['est_monthly_savings']:,.2f}/mo"
        ):
            st.write(rec["description"])
            st.caption(f"Resource: {rec['resource']}  |  Compartment: {rec['compartment']}")

st.markdown("---")
st.caption(
    f"Last refreshed: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')} · "
    "OCI FinOps Monitor (Linux edition)"
)
