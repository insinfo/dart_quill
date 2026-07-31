library diff_match_patch;

export 'core/diff.dart'
    show
        Diff,
        diff,
        cleanupSemantic,
        cleanupEfficiency,
        levenshtein,
        DIFF_DELETE,
        DIFF_INSERT,
        DIFF_EQUAL;

export 'core/match.dart' show match;

export 'core/patch.dart'
    show Patch, patchMake, patchToText, patchFromText, patchApply;

export 'core/api.dart' show DiffMatchPatch;
