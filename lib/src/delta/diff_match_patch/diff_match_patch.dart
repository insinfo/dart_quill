library diff_match_patch;

export 'src/diff.dart'
    show
        Diff,
        diff,
        cleanupSemantic,
        cleanupEfficiency,
        levenshtein,
        DIFF_DELETE,
        DIFF_INSERT,
        DIFF_EQUAL;

export 'src/match.dart' show match;

export 'src/patch.dart'
    show Patch, patchMake, patchToText, patchFromText, patchApply;

export 'src/api.dart' show DiffMatchPatch;
