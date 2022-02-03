# --
# Copyright (C) 2018 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminCustomerUserCheckAndDelete;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Web::Request
    Kernel::System::HTMLUtils
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

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my @ArrayParams = (qw(CustomerID Checks));
    my %GetParam;
    for (@ArrayParams) {
        $GetParam{$_} = [ $ParamObject->GetArray( Param => $_ ) ];
    }

    # ------------------------------------------------------------ #
    # get data 2 form
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Delete' ) {
        my $Module = $ConfigObject->Get('CustomerUserCheckAndDelete::DeleteModule');
        my $Object = $Kernel::OM->Get($Module);

        $Object->Run(
            %GetParam,
        );

        return $LayoutObject->Redirect(
           OP => 'Action=AdminCustomerUserCheckAndDelete', 
        );
    }

    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $Self->_CustomerUsers( %GetParam );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _CustomerUsers {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my %Checks = %{ $ConfigObject->Get('CustomerUserCheckAndDelete::Check') || {} };

    $Param{Checks} = [keys %Checks] if !IsArrayRefWithData( $Param{Checks} );

    my @CheckSelect = map{
        my $LastPart = (split /::/, $Checks{$_}->{Module})[-1];
        my $Label    = $Checks{$_}->{Label} // $LastPart;

        +{
            Key   => $_,
            Value => $Label,
        };
    } keys %Checks;

    $Param{CheckSelect} = $LayoutObject->BuildSelection(
        Name        => 'Checks',
        Data        => \@CheckSelect,
        SelectedIDs => $Param{Checks} // [ keys %Checks ],
        Multiple    => 1,
        Size        => 5,
    );

    my $Limit    = $ConfigObject->Get('CustomerUserCheckAndDelete::Limit') || 1000;
    my %UserList = $CustomerUserObject->CustomerSearch(
        Search => '*',
        Valid  => 0,
        Limit  => $Limit,
    );

    my @UserIDs = keys %UserList;

    CHECK:
    for my $Check ( @{ $Param{Checks} || [] } ) {
        next CHECK if !$Checks{$Check};

        my $Module = $Checks{$Check}->{Module};
        next CHECK if !$Module;

        my $Object = $Kernel::OM->Get( $Module );
        next CHECK if !$Object;
        next CHECK if !$Object->can('Run');

        @UserIDs = $Object->Run(
            CustomerID => \@UserIDs,
        );
    }

    if ( !@UserIDs ) {
        $LayoutObject->Block(
            Name => 'NoUsersFound',
        );
    }

    for my $UserID ( sort { $UserList{$a} cmp $UserList{$b} } @UserIDs ) {
        my %User = $CustomerUserObject->CustomerUserDataGet(
            User => $UserID,
        );

        $LayoutObject->Block(
            Name => 'UserRow',
            Data => \%User,
        );
    }

    return $LayoutObject->Output(
        TemplateFile => 'AdminCustomerUserCheckAndDelete',
        Data         => \%Param
    );
}

1;
