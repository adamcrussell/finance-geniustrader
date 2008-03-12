package GT::Indicators::EMA;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# Copyright 2008 Thomas Weigert
# Based on and for GeniusTrader (C) 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

# $Id$

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;

@ISA = qw(GT::Indicators);
@NAMES = ("EMA[#*]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::EMA - Exponential Moving Average

=head1 DESCRIPTION

An exponential moving average gives more importance to
recent prices ...

=head2 Parameters

=over

=item Period (default 20)

The first argument is the period used to calculate the average.

=item Other data input

The second argument is optional. It can be used to specify an other
stream of input data for the average instead of the close prices.
This is usually an indicator (detailed via {I:MyIndic <param>}).

=back

=head2 Calculation

alpha = 2 / ( N + 1 )
EMA[n] = EMA[n-1] + alpha * ( INPUT - EMA[n-1] )

In TA, the first value is often constructed as SMA(N).

Note: One criticism could be that the EMA is calculated starting
from the designated period. But actually the EMA goes all the way back
to the beginning of the available data. But in all tools I checked they
start computation from the loaded data on.

=head2 Creation

 GT::Indicators::EMA->new()
 GT::Indicators::EMA->new([20])

If you need a 30 days EMA of the opening prices you can write
one of these lines:

 GT::Indicators::EMA->new([30, "{I:Prices OPEN}"])

A 10 days EMA of the RSI could be created with :

 GT::Indicators::EMA->new([10, "{I:RSI}"])

Z<>

=cut
sub initialize {
    my ($self) = @_;

    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names() ]);
    $self->add_indicator_dependency($self->{'sma'}, 1);

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;
    my $before = 1;

    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    return if (! defined($nb));

    return if ($indic->is_available($name, $i));
    return if ($before && ! $self->check_dependencies($calc, $i));

    my $alpha = 2 / ($nb + 1);

    my $oldema = $indic->get($name, $i - 1);
    my $ema;
    if (defined $oldema) {
      $ema = $alpha * ($self->{'args'}->get_arg_values($calc, $i, 2) - $oldema) + $oldema;
    } else {
      $ema = $indic->get($self->{'sma'}->get_name, $i);
      $before = 0;
    }
    $indic->set($name, $i, $ema);

}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;

    my $nb = $self->{'args'}->get_arg_constant(1);
    return if (! defined($nb));

    return if ($indic->is_available_interval($name, $first, $last));
    # Don't need to calculate all SMA values, just the first data point.
    $self->{'sma'}->calculate($calc, $first);

    return unless $self->dependencies_are_available($calc, $first);

    my $alpha = 2 / ($nb + 1);

    $indic->set($name, $first, $indic->get($self->{'sma'}->get_name, $first));

    for (my $i=$first+1;$i<=$last;$i++) {
      my $oldema = $indic->get($name, $i - 1);
      my $ema = $alpha * ($self->{'args'}->get_arg_values($calc, $i, 2) - $oldema) + $oldema;
      $indic->set($name, $i, $ema);
    }
}

1;
