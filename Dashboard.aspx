<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Target Albany Dashboard</title>
  <style>
    body {
      background:#111;
      color:#fff;
      font-family:Segoe UI, sans-serif;
      margin:0;
      padding:20px;
    }
    h1, h2 { margin-top:0; }
    .tile {
      flex:1;
      min-width:220px;
      background:#1e1e1e;
      padding:20px;
      border-radius:8px;
    }
    table {
      width:100%;
      color:#fff;
      border-collapse:collapse;
      font-size:14px;
    }
    th, td {
      padding:8px;
      border-bottom:1px solid #333;
      text-align:left;
    }
    a { color:#4da3ff; }
  </style>
</head>

<body>

  <h1 style="text-align:center; margin-bottom:30px;">
    Target Albany – Safety & Operations Dashboard
  </h1>

  <!-- KPI Tiles -->
  <div style="display:flex; flex-wrap:wrap; gap:20px; margin-bottom:30px;">
    <div class="tile">
      <h2>Not Completed Safety Video</h2>
      <p id="kpi_not_completed_value" style="font-size:32px; font-weight:bold;">--</p>
    </div>

    <div class="tile">
      <h2>Upcoming Events</h2>
      <p id="kpi_upcoming_events_value" style="font-size:32px; font-weight:bold;">--</p>
    </div>
  </div>

  <!-- Safety Video Table -->
  <div class="tile" style="margin-bottom:30px;">
    <h2>People Who Haven't Completed Safety Video</h2>
    <table id="safety_table">
      <thead>
        <tr>
          <th>Name</th>
          <th>Location</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody></tbody>
    </table>
  </div>

  <!-- Upcoming Events -->
  <div class="tile" style="margin-bottom:30px;">
    <h2>Upcoming Events</h2>
    <ul id="events_list" style="list-style:none; padding-left:0; margin:0;"></ul>
  </div>

  <!-- Quick Links -->
  <div class="tile">
    <h2>Most Used Links</h2>
    <ul id="quick_links" style="list-style:none; padding-left:0; margin:0;"></ul>
  </div>

<script>
// IMPORTANT: This file runs inside an iframe.
// It cannot detect the SharePoint site automatically.
// So you MUST set your site URL here:

const siteUrl = "https://england365.sharepoint.com/sites/TargetAlbany";

// Generic SharePoint REST fetch
async function getList(listName) {
  const url = `${siteUrl}/_api/web/lists/getbytitle('${listName}')/items`;
  const response = await fetch(url, {
    headers: { "Accept": "application/json;odata=verbose" },
    credentials: "include"
  });

  if (!response.ok) {
    throw new Error(`List '${listName}' not found or not accessible`);
  }

  const data = await response.json();
  return data.d.results;
}

/* =========================
   SAFETY VIDEO
   ========================= */
async function loadSafety() {
  try {
    const items = await getList("SafetyVideo");
    const notDone = items.filter(i => i.Status !== "Completed");

    document.getElementById("kpi_not_completed_value").innerText = notDone.length;

    const tbody = document.querySelector("#safety_table tbody");
    tbody.innerHTML = "";

    notDone.forEach(person => {
      tbody.innerHTML += `
        <tr>
          <td>${person.Title || ""}</td>
          <td>${person.Location || ""}</td>
          <td style="color:#f55;">${person.Status || "Not Completed"}</td>
        </tr>`;
    });

  } catch (e) {
    console.error("Error loading SafetyVideo:", e);
    document.getElementById("kpi_not_completed_value").innerText = "ERR";
  }
}

/* =========================
   EVENTS (Calendar → List fallback)
   ========================= */
async function loadEvents() {
  let items = [];

  try {
    items = await getList("Target Albany Daily Events");
  } catch (e) {
    console.warn("Calendar not found, using Events list.");
    try {
      items = await getList("Events");
    } catch (err) {
      console.error("No event source available:", err);
      document.getElementById("kpi_upcoming_events_value").innerText = "ERR";
      return;
    }
  }

  const now = new Date();

  const upcoming = items
    .filter(i => i.EventDate)
    .map(i => ({
      title: i.Title || "(No title)",
      start: new Date(i.EventDate),
      end: i.EndDate ? new Date(i.EndDate) : null,
      location: i.Location || ""
    }))
    .filter(ev => ev.start >= now)
    .sort((a, b) => a.start - b.start);

  document.getElementById("kpi_upcoming_events_value").innerText = upcoming.length;

  const ul = document.getElementById("events_list");
  ul.innerHTML = "";

  upcoming.slice(0, 5).forEach(ev => {
    const dateStr = ev.start.toLocaleString();
    ul.innerHTML += `
      <li style="margin-bottom:10px; border-bottom:1px solid #333; padding-bottom:6px;">
        <div style="font-weight:bold;">${ev.title}</div>
        <div style="font-size:12px; color:#ccc;">${dateStr}${ev.location ? " – " + ev.location : ""}</div>
      </li>`;
  });

  if (upcoming.length === 0) {
    ul.innerHTML = `<li style="color:#aaa;">No upcoming events.</li>`;
  }
}

/* =========================
   QUICK LINKS
   ========================= */
async function loadLinks() {
  try {
    const items = await getList("QuickLinks");
    const ul = document.getElementById("quick_links");
    ul.innerHTML = "";

    items.forEach(link => {
      const url = link.Url && link.Url.Url ? link.Url.Url : link.Url || "#";
      const text = link.Title || (link.Url && link.Url.Description) || "Link";

      ul.innerHTML += `
        <li style="margin-bottom:10px;">
          <a href="${url}" target="_blank" rel="noopener noreferrer">${text}</a>
        </li>`;
    });

  } catch (e) {
    console.error("Error loading QuickLinks:", e);
  }
}

/* =========================
   REFRESH LOOP
   ========================= */
function refreshAll() {
  loadSafety();
  loadEvents();
  loadLinks();
}

refreshAll();
setInterval(refreshAll, 300000);
</script>

</body>
</html>