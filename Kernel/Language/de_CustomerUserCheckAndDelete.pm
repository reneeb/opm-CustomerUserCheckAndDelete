# --
# Copyright (C) 2020 - 2022 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_CustomerUserCheckAndDelete;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{"Customer Users - check and delete"} = "Kundenbenutzer prüfen und löschen";
    $Lang->{"Check Customer Users"}              = "Kundenbenutzer prüfen";
    $Lang->{"Delete Customer Users"}             = "Kundenbenutzer löschen";
    $Lang->{"Customer Users Check"}              = "Kundenbenutzerprüfung";
    $Lang->{"Check and delete customer users."}  = "Kundenbenutzer prüfen und löschen";
    $Lang->{'Check/Uncheck all'}                 = 'Alle aus-/abwählen';

    return 1;
}

1;
