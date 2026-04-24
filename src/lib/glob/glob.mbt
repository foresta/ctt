///|
/// A gitignore-style glob pattern.
pub(all) struct GlobPattern {
  pattern : String
  negated : Bool
  anchored : Bool
} derive(Show, Eq)

///|
/// Parse a gitignore-style pattern line. Returns None for empty lines and comments.
pub fn parse(line : String) -> GlobPattern? {
  let trimmed = line.trim_end().to_string()
  if trimmed == "" || trimmed.has_prefix("#") {
    return None
  }
  let mut s = trimmed
  let negated = s.has_prefix("!")
  if negated {
    s = s[1:].to_string()
  }
  if s.has_suffix("/") {
    s = s[:s.length() - 1].to_string()
  }
  let anchored = s.has_prefix("/") || contains_slash(s)
  if s.has_prefix("/") {
    s = s[1:].to_string()
  }
  Some(GlobPattern::{ pattern: s, negated, anchored })
}

///|
fn contains_slash(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '/' {
      return true
    }
  }
  false
}

///|
/// Check if a path matches this pattern.
pub fn GlobPattern::matches(self : GlobPattern, path : String) -> Bool {
  if self.anchored {
    glob_match(self.pattern, path)
  } else {
    // Non-anchored: try full path first, then try matching against basename
    if glob_match(self.pattern, path) {
      return true
    }
    // Try matching against just the basename (last component)
    glob_match(self.pattern, @path.basename(path))
  }
}

///|
/// Core glob matching: match pattern against text.
fn glob_match(pattern : String, text : String) -> Bool {
  glob_match_at(pattern, 0, text, 0)
}

///|
fn glob_match_at(
  pattern : String,
  pi : Int,
  text : String,
  ti : Int
) -> Bool {
  let plen = pattern.length()
  let tlen = text.length()
  // Use iterative backtracking for single * to avoid deep recursion
  let mut pi = pi
  let mut ti = ti
  let mut star_pi = -1
  let mut star_ti = -1
  while pi < plen || ti < tlen {
    if pi < plen {
      // Check for **
      if pi + 1 < plen && pattern[pi] == '*' && pattern[pi + 1] == '*' {
        return match_doublestar(pattern, pi, text, ti)
      }
      if pattern[pi] == '*' {
        // Single *: matches zero or more non-'/' chars
        star_pi = pi
        star_ti = ti
        pi = pi + 1
        continue
      }
      if ti < tlen {
        if pattern[pi] == '?' {
          if text[ti] != '/' {
            pi = pi + 1
            ti = ti + 1
            continue
          }
        } else if pattern[pi] == text[ti] {
          pi = pi + 1
          ti = ti + 1
          continue
        }
      }
    }
    // Mismatch: try backtracking on single *
    if star_pi >= 0 && star_ti < tlen && text[star_ti] != '/' {
      star_ti = star_ti + 1
      ti = star_ti
      pi = star_pi + 1
      continue
    }
    return false
  }
  true
}

///|
/// Handle ** patterns. Called when pattern[pi] == '*' && pattern[pi+1] == '*'.
fn match_doublestar(
  pattern : String,
  pi : Int,
  text : String,
  ti : Int
) -> Bool {
  let plen = pattern.length()
  // Advance past **
  let mut next_pi = pi + 2
  // If ** is followed by /, skip the /
  if next_pi < plen && pattern[next_pi] == '/' {
    next_pi = next_pi + 1
  }
  // ** matches everything: try matching rest of pattern at every position
  // including current position and after each /
  if glob_match_at(pattern, next_pi, text, ti) {
    return true
  }
  let tlen = text.length()
  for i = ti; i < tlen; i = i + 1 {
    if text[i] == '/' {
      if glob_match_at(pattern, next_pi, text, i + 1) {
        return true
      }
    }
  }
  // Also try matching ** against remaining text (** at end of pattern)
  if next_pi >= plen {
    return true
  }
  false
}
