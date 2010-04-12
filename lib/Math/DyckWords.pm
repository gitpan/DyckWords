#######################################################################
# $Id: $

=head1 NAME

Math::DyckWords - Perl module for generating Dyck words. The functions
in this moduloe are based on those presented in the scholarly paper
"Generating and ranking of Dyck words" by Zoltan Kasa available on-line
at http://arxiv4.library.cornell.edu/pdf/1002.2625

=head1 SYNOPSIS

  use Math::DyckWords qw( dyck_words_by_lex
                          dyck_words_by_position
                          dyck_words_by_swap
                          ranking
                          unranking );

  foreach my $word ( dyck_words_by_lex( 4 ) ) {
      print "word: $word\n";
      print "rank:" . ranking( $word ) . "\n";
  }

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=cut

package Math::DyckWords;

use 5.006;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Exporter;

our $VERSION = '0.01';
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( dyck_words_by_lex
                     dyck_words_by_position
                     dyck_words_by_swap
                     ranking
                     unranking );

# The algorithm that generates all Dyck words in lexicographic
# order is obvious. Let us begin with 0 in the 1st position,
# and add 0 or 1 each time the Dyck-property remains valid.
# In the following algorithm 2n is the length of a Dyck word,
# n0 counts the 0s, and n1 the 1s.

my @words;

sub dyck_words_by_lex {
    my ( $n, $X, $i, $n0, $n1 ) = @_;

    # initialization - the first time called, the only argument
    # is the length 2n of the words
    if( not defined $X ) {
        ( $X, $i, $n0, $n1 )  = ( '0', 1, 1, 0 );
        @words = ();
    }

    # Case 1: We can continue by adding 0 and 1.
    if( $n0 < $n && $n1 < $n && $n0 > $n1 ) {
        dyck_words_by_lex( $n, $X . '0', $i++, $n0 + 1, $n1 );
        dyck_words_by_lex( $n, $X . '1', $i++, $n0, $n1 + 1 );
    }

    # Case 2: We can continue by adding 0 only.
    if( ( $n0 < $n && $n1 < $n && $n0 == $n1 ) ||
        ( $n0 < $n && $n1 == $n ) )
    {
        dyck_words_by_lex( $n, $X . '0', $i++, $n0 + 1, $n1 );
    }

    # Case 3: We can continue by adding 1 only.
    if( $n0 == $n && $n1 < $n  ) {
        dyck_words_by_lex( $n, $X . '1', $i++, $n0, $n1 + 1 );
    }

    # Case 5: A Dyck word is obtained.
    if( $n0 == $n && $n1 == $n ) {
        push @words, $X;
    }

    # All Dyck words have been obtained
    return @words;
}


sub dyck_words_by_position {
    my $n = shift;

    # reset the return list
    @words = ();

    # generate the maximum Dyck word of length n - which has 1s in all
    # even numbered positions, i.e. 2468 = 01010101
    my @b = map { $_ * 2 } ( 1 .. $n );

    # set a flag
    my $found = 1;

    while( $found ) {
        # save the Dyck word to the return list
        push @words, translate_positions( @b );

        # reset flag
        $found = 0;

        # reverse iterate through the length of the word
        # setting the appropriate bits to 1's or 0's
        for( my $i = $n - 1; $i >= 1; $i-- ) {
	        if( $b[ $i - 1 ] < $n + $i ) {
                $b[ $i - 1 ] += 1;

                for( my $j = $i + 1; $j <= $n - 1; $j++ ) {
		            $b[ $j - 1 ] = $b[ $j - 2 ] + 1 > $j * 2
                                 ? $b[ $j - 2 ] + 1
                                 : $j * 2;
		        }
		        $found = 1;
                last; 
	        }
	    }
    }
    return @words;
}

# translates an array of integer values which indicate
# the position of 1's in the resultant Dyck word
sub translate_positions( @ ) {
    my $n = scalar @_;

    # convert the list of positions to a hash for easier lookup
    my %position;
    @position{ @_ } = @_;

    my $word;
    for( my $i = 0; $i < $n * 2; $i++ ) {
        $word .= exists $position{ $i + 1 } ? '1' : '0';
    }
    return $word;
}

# Generating by changing 10 in 01
# The basic idea is to change the first occurence of 10 in 01
# to get a new Dyck word. We begin with 0101 ...  01.
sub dyck_words_by_swap {
    my ( $n, $X, $k ) = @_;

    if( not defined $X ) {
        $X = join '', ( '01' x $n );
        $k = 0;
        @words = ( $X );
    }

    my $i = $k;

    while( $i < $n * 2 ) {
        my $j = index( $X, '10', $i );
        if( $j > 0 ) {
            my @Y = split //, $X;
            # swap
            ( $Y[ $j ], $Y[ $j + 1 ] ) =
                ( $Y[ $j + 1 ], $Y[ $j ] );
            my $Y = join '', @Y;
            push @words, $Y;
            dyck_words_by_swap( $n, $Y, $j - 1 );
            $i = $j + 2;
        }
        else {
            return @words;
        }
    }
}

# Ranking Dyck words means to determine the position of a Dyck
# word in a given ordered sequence of all Dyck words.
# Algorithm dyck_words_by_position generates all Dyck word in
# reverse lexicographic order. For ranking these words we will
# use the following function , where f(n,i,j) represents the number
# of paths between (0,0) and (i,j) not crossing the diagonal
# x = y of the grid.
sub monotonic_path_count {
    my ( $n, $i, $j ) = @_;

    if( $n >= $i and $i >= 0 and $j == 0 ) {
        return 1;
    }
    if( $n >= $i and $i > $j and $j >= 1 ) {
        return monotonic_path_count( $n, $i - 1, $j ) +
	           monotonic_path_count( $n, $i, $j - 1 );
    }
    if( $n >= $i and $i >= 1 and $j == $i ) {
        return monotonic_path_count( $n, $i, $i - 1 );
    }
    if( $n >= $j and $j > $i and $i >= 0 ) {
        return 0;
    }
}

# converts a dyck word string of 1's and 0's into a list
# of positions where the 1's are located, i.e. 2468
sub positions( $ ) {
    my $w = shift;

    my ( $i, @p ) = ( 1, () );
    foreach my $p ( split //, $w ) {
        if( $p == 1 ) {
            push @p, $i;
        }
        $i++;
    }
    return @p;
}

sub ranking( $ ) {
    my @b = positions( shift );

    my @c = ( 2 );
    my $n = scalar @b;
    for( my $j = 2; $j <= $n; $j++ ) {
	    $c[ $j - 1 ] = $b[ $j - 2 ] + 1 > $j * 2
	                 ? $b[ $j - 2 ] + 1
                 : $j * 2;
    }
    my $nr = 1;
    for( my $i = 1; $i <= $n - 1; $i++ ) {
	    for( my $j = $c[ $i - 1]; $j <= $b[ $i - 1] - 1; $j++ ) {
	        $nr = $nr + monotonic_path_count( $n, $n - $i, $n + $i - $j );
	    }
    }
    return $nr;
}

sub unranking( $$ ) {
    my ( $n, $nr ) = @_;

    # initialize the dyck word to all '0'
    my @b = ( '0' x ( $n * 2 ) );

    $nr--;

    for( my $i = 1; $i <= $n; $i++ ) {
	    $b[ $i ] = $b[ $i - 1 ] + 1 > $i * 2
                 ? $b[ $i - 1 ] + 1
                 : $i * 2;

	    my $j  = $n + $i - $b[ $i ];
	    my $np = monotonic_path_count( $n, $n - $i, $j );

	    while( $nr >= $np && ( $b[ $i ] < $n + $i ) ) {
	        $nr      = $nr - $np;
	        $b[ $i ] = $b[ $i ] + 1;
	        $j       = $j - 1;
            $np      = monotonic_path_count( $n, $n - $i, $j );
	    }
    }
    # discard the zeroth element of the list of positions
    shift @b;

    return translate_positions( @b );
}

1;
