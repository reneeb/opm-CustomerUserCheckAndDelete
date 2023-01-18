# --
# Copyright (C) 2018 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PerlServices::CustomerUserDelete;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::DB
    Kernel::System::Cache
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

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

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
        DELETE FROM customer_user
        WHERE login IN ( $Placeholder )
    ~;

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => [ map { \$_ }@CustomerUserIDs ],
    );

    my @Prefixes = qw(
        CustomerUserDataGet
        CustomerName
        CustomerIDs
    );

    for my $CustomerUserID ( @CustomerUserIDs ) {
        for my $Prefix ( @Prefixes ) {
            my $Key = join '::', $Prefix, $CustomerUserID;

            $CacheObject->Delete(
                Type => 'CustomerUser',
                Key  => $Key,
            );
        }
    }

    my @CacheTypes = qw/
        CustomerUser
        CustomerUser_CustomerSearch
        CustomerUser_CustomerSearchDetail
        CustomerUser_CustomerSearchDetailDynamicFields
        CustomerUser_CustomerIDList
    /;

    for my $CacheType ( @CacheTypes ) {
        $CacheObject->CleanUp(
            Type => $CacheType,
        );
    }

    return 1;
}

1;
