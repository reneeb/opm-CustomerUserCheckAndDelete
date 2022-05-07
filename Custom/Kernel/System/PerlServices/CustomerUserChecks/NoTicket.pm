# --
# Copyright (C) 2018 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PerlServices::CustomerUserChecks::NoTicket;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::DB
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

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    if ( !ref $Param{CustomerID} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need CustomerID array ref',
        );

        return;
    }

    my @CustomerUserIDs = @{ $Param{CustomerID} || [] };
    my $Placeholder     = join ', ', ('?') x @CustomerUserIDs;

    return if !$Placeholder;

    my $SQL = qq~
        SELECT DISTINCT customer_user_id
        FROM ticket
        WHERE customer_user_id IN ( $Placeholder )
    ~;

    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => [ map { \$_ }@CustomerUserIDs ],
    );

    my %UserIDs = map { $_ => 1 } @CustomerUserIDs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        delete $UserIDs{ $Row[0] };
    }

    return keys %UserIDs;
}

1;
