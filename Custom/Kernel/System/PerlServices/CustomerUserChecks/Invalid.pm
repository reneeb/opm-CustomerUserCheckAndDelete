# --
# Copyright (C) 2020 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PerlServices::CustomerUserChecks::Invalid;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::CustomerUser
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    if ( !ref $Param{CustomerID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need CustomerID array ref',
        );

        return;
    }

    my %CustomerUserIDs = map{ $_ => 1 }@{ $Param{CustomerID} || [] };

    my %ValidCustomerUsers = $CustomerUserObject->CustomerSearch(
        Search => '*',
        Valid  => 1,
    );

    delete @CustomerUserIDs{ keys %ValidCustomerUsers };

    return keys %CustomerUserIDs;
}

1;
