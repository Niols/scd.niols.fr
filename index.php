<!DOCTYPE html>
<head>
    <title>Niols's Collection of (Mostly Unpublished) Scottish Country Dances</title>

    <meta charset="utf-8" />

    <!-- Basic style -->
    <link rel="stylesheet" href="/reset.css">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css" integrity="sha384-oS3vJWv+0UjzBfQzYUhtDYW+Pj2yciDJxpsK1OYPAYjqT085Qq/1cq5FLXAZQ7Ay" crossorigin="anonymous">

    <!-- Style -->
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <header>
        <h1>Niols's Collection of (Mostly Unpublished) Scottish Country Dances</h1>
    </header>

    <table>
        <?php

        function str_ends_with($haystack, $needle) {
            $length = strlen($needle);
            if (!$length) {
                return true;
            }
            return substr($haystack, -$length) === $needle;
        }

        function get_entry($dir, $ext, $die_on_no_entry=true) {
            $entries = scandir($dir);
            $entries = array_filter($entries, function($entry)use($ext){return str_ends_with($entry, ".".$ext);});
            switch (count($entries)) {
                case 0: if ($die_on_no_entry) die("no entry"); else return null; break;
                case 1: return $dir . "/" . array_shift($entries); break;
                default: die("more than one entry"); break;
            }
        }

        $dances = scandir("dance/");

        foreach($dances as $dance) {
            $dance_dir = "dance/" . $dance;

            $meta_entry = get_entry($dance_dir, "json", false);
            if ($meta_entry === null) continue;
            $meta = json_decode(file_get_contents($meta_entry));
            $link = get_entry($dance_dir, "pdf");

            // Skip those marked as hidden.
            if (isset($meta->hidden) && $meta->hidden) continue;

            printf("<tr>\n");
            printf("  <td class=\"name\">%s</td>\n", $meta->name);
            printf("  <td class=\"kind\">%s</td>\n", $meta->kind);
            printf("  <td class=\"author\">%s</td>\n", $meta->author);

            printf("  <td class=\"action\"><a href=\"%s\"><i class=\"fas fa-file-pdf\"></i></a></td>", $link);

            if (isset($meta->{"scddb-id"}) && $meta->{"scddb-id"}) {
                printf("  <td class=\"action\"><a href=\"https://my.strathspey.org/dd/dance/%d/\"><i class=\"fas fa-database\"></i></a></td>", $meta->{"scddb-id"});
            } else {
                printf("  <td class=\"action\"></td>");
            }
            printf("</tr>\n");
        }

        ?>
    </table>
</body>
</html>
