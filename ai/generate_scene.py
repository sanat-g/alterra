import subprocess, json, re, sys, pathlib

MODEL = "llama3.1"

SCHEMA = """
Return ONLY valid JSON with this schema:

{
  "scenario": "string",
  "year": 2025,

  "focus_region": {
    "country": "string",
    "admin1": "string",
    "nearest_city": "string",
    "lat": 0.0,
    "lon": 0.0,
    "why_here": "string"
  },

  "scene": {
    "size_m": [250, 250],
    "terrain": { "type": "flat|hilly|coastal|river|urban_ruins|forest", "seed": 12345 },
    "biome": "temperate|mediterranean|tropical|desert|tundra|urban|mixed",
    "mood": { "sky": "clear|sunset|storm|hazy|night", "lighting": "warm|cool|dramatic" },

    "pois": [
      {
        "type": "temple|market|lab|factory|nest|fort|plaza|monument|watchtower",
        "style": "ancient|medieval|industrial|modern|futuristic|prehistoric|hybrid",
        "name": "string",
        "pos": [x, z],
        "radius_m": 12,
        "one_liner": "string",
        "because": "string",
        "depends_on": ["string", "string"]
      }
    ]
  },

  "global_context": ["bullet", "bullet", "bullet"]
}

REALISM CONSTRAINTS (must follow):
- focus_region.country/admin1/nearest_city MUST be real places on Earth. Do NOT invent place names.
- focus_region.lat must be between -90 and 90; focus_region.lon between -180 and 180.
- The focus region should be a real-world area most physically impacted by the scenario.
- POI "name" can be speculative, but SHOULD NOT invent new countries/cities/regions.
  (e.g., avoid "Neo-Rome Province", "Dino Coast Republic".)
- Each POI one_liner must reference real-world context tied to the focus_region (place, climate, infrastructure, etc.)
- Each POI because must explain WHY this POI exists as a consequence of the scenario in this specific region.

RELATIONSHIP RULES (must follow):
- Each POI must include "because" (short cause-effect justification tied to scenario + focus_region).
- "depends_on" must be an array of 0–2 OTHER POI NAMES from this same JSON output.
  It must match those POI names exactly (string match).
- At least 3 POIs should have a non-empty depends_on so the scene forms a small network.

RULES:
- Choose ONE focus region most impacted by the scenario.
- Produce 12–16 POIs.
- pos x,z must be within -125..125.
- depends_on must reference existing POI names only.
- Keep it visually distinctive and plausible.
- Return JSON only. No markdown, no commentary.
"""

PROMPT_TMPL = """
You are designing a small explorable 3D diorama for an alternate-history scenario.

Scenario: {scenario}

Goal:
- Pick ONE real-world focus region on Earth most physically impacted by the scenario.
- Describe a 250m x 250m scene a player can explore.

Grounding requirements:
- Use real country/admin region (state/province) and nearest major city.
- Provide plausible latitude/longitude for the focus region.
- Do NOT invent place names.

POI requirements:
- Create 6–10 POIs with coordinates inside the scene.
- Each POI must have:
  - name, type, style, pos, radius_m, one_liner
  - because: why it exists because of the scenario in this region
  - depends_on: 0–2 names of other POIs from the same output

Before returning JSON, quickly self-check:
- Are the focus_region names real?
- Are lat/lon in valid ranges?
- Are POIs plausible consequences of the scenario in that real place?
- Do depends_on entries match other POI names exactly?

{schema}
"""

def run_ollama(prompt: str) -> str:
    p = subprocess.run(
        ["ollama", "run", MODEL],
        input=prompt.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr.decode("utf-8"))
    return p.stdout.decode("utf-8")

def extract_json(text: str) -> dict:
    s = text.strip()

    # Find the first '{' and last '}' anywhere in the output
    start = s.find("{")
    end = s.rfind("}")

    if start == -1 or end == -1 or end <= start:
        raise ValueError("No JSON object found.")

    candidate = s[start:end+1]

    try:
        return json.loads(candidate)
    except json.JSONDecodeError as e:
        # Helpful debug so you can see what it returned
        raise ValueError(f"Found braces but JSON was invalid: {e}\n\nRaw model output:\n{s}")

def main():
    scenario = "What if dinosaurs never died?"
    out_path = None

    args = sys.argv[1:]
    if "--out" in args:
        i = args.index("--out")
        out_path = args[i + 1]
        # remove --out and its value so remaining args become scenario
        del args[i:i+2]

    if len(args) > 0:
        scenario = " ".join(args)

    prompt = PROMPT_TMPL.format(scenario=scenario, schema=SCHEMA)
    raw = run_ollama(prompt)
    data = extract_json(raw)

    payload = json.dumps(data, indent=2)

    game_out = (pathlib.Path(__file__).parent / ".." / "game" / "scene.json").resolve()
    game_out.write_text(payload, encoding="utf-8")
    print("Wrote:", game_out)


if __name__ == "__main__":
    main()