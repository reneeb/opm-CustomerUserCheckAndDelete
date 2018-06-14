# --
# Copyright (C) 2018 Perl-Services.de, http://perl-services.de
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
        DELETE FROM customer_user
        WHERE login IN ( $Placeholder )
    ~;

    return if !$DBObject->Do(
        SQL  => $SQL,
        Bind => [ map { \$_ }@CustomerUserIDs ],
    );

    $Self->{CacheType}   = 'CustomerUser';
    $Self->{CacheObject} = $Kernel::OM->Get('Kernel::System::Cache');

    for my $Login ( @CustomerUserIDs ) {
        $Self->_CustomerUserCacheClear(
            UserLogin => $Login,
        );
    }

    return 1;
}

sub _CustomerUserCacheClear {
    my ( $Self, %Param ) = @_;

    return if !$Self->{CacheObject};

    if ( !$Param{UserLogin} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserLogin!',
        );
        return;
    }

    $Self->{CacheObject}->Delete(
        Type => $Self->{CacheType},
        Key  => "CustomerUserDataGet::$Param{UserLogin}",
    );
    $Self->{CacheObject}->Delete(
        Type => $Self->{CacheType},
        Key  => "CustomerName::$Param{UserLogin}",
    );
    $Self->{CacheObject}->Delete(
        Type => $Self->{CacheType},
        Key  => "CustomerIDs::$Param{UserLogin}",
    );

    # delete all search cache entries
    $Self->{CacheObject}->CleanUp(
        Type => $Self->{CacheType} . '_CustomerIDList',
    );
    $Self->{CacheObject}->CleanUp(
        Type => $Self->{CacheType} . '_CustomerSearch',
    );

    $Self->{CacheObject}->CleanUp(
        Type => 'CustomerGroup',
    );

    for my $Function (qw(CustomerUserList)) {
        for my $Valid ( 0 .. 1 ) {
            $Self->{CacheObject}->Delete(
                Type => $Self->{CacheType},
                Key  => "${Function}::${Valid}",
            );
        }
    }

    return 1;
}

1;
