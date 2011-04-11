package Data::Overlay;

use warnings;
use strict;
use Carp;
use Scalar::Util qw(reftype refaddr);
use List::Util qw(reduce);
use List::MoreUtils qw(part);
use Exporter 'import';
use YAML::XS; # XXX

our $VERSION = '1.01';
our @EXPORT_OK = qw(overlay overlay_all compose);

# XXX
my @action_order = qw(default or unshift shift push pop foreach seq run);
my %action_map;
my $default_conf = {
        action_map => \%action_map,
        state      => {},
        protocol   => {},
    };
# weaken( $default_conf->{action_map} ); XXX

%action_map = (
    config   => sub {
                    my ($old_ds, $overlay, $conf) = @_;

                    # start using $conf param
                    if (!defined $conf) {
                        $conf = { };
                    } elsif (reftype($conf) eq 'HASH') {
                        $conf = { %$conf, %$default_conf };
                    }

                    return overlay($old_ds, $overlay->{data},
                                        overlay($conf, $overlay->{conf}));
                },
    defaults => sub {
                    my ($old_ds, $overlay, $conf) = @_;

                    if (    reftype($old_ds)  eq 'HASH'
                         && reftype($overlay) eq 'HASH' ) {
                        my %new_ds = %$old_ds; # shallow copy
                        for (keys %$overlay) {
                            $new_ds{$_} //= $overlay->{$_};
                        }
                        return \%new_ds;
                    } else {
                        return $old_ds // $overlay; # only HASHes have defaults
                    }
                },
    default => sub {
                    my ($old_ds, $overlay) = @_;
                    return $old_ds // $overlay;
                },
    or      => sub {
                    my ($old_ds, $overlay) = @_;
                    return $old_ds || $overlay;
                },
    push    => sub {
                    my ($old_ds, $overlay) = @_;
                    if (reftype($old_ds) eq 'ARRAY') {
                        return [ @$old_ds, $overlay ];
                    } else {
                        return [ $old_ds, $overlay ]; # one elem array
                    }
                },
    unshift => sub {
                    my ($old_ds, $overlay) = @_;
                    if (reftype($old_ds) eq 'ARRAY') {
                        return [ $overlay, @$old_ds ];
                    } else {
                        return [ $overlay, $old_ds ]; # "one elem array"
                    }
                },
    pop     => sub {
                    my ($old_ds, $overlay) = @_;
                    if (reftype($old_ds) eq 'ARRAY') {
                        return [ @{$old_ds}[0..$#$old_ds-1] ];
                    } else {
                        return [ ]; # pop "one elem array"
                    }
                },
    shift   => sub {
                    my ($old_ds, $overlay) = @_;
                    if (reftype($old_ds) eq 'ARRAY') {
                        return [ @{$old_ds}[1..$#$old_ds] ];
                    } else {
                        return [ ]; # shift "one elem array"
                    }
                },
    run    => sub {
                    my ($old_ds, $overlay) = @_;
                    return $overlay->{code}->($old_ds, $overlay->{args});
                },
    foreach => sub {
                    my ($old_ds, $overlay, $conf) = @_;
                    if (reftype($old_ds) eq 'ARRAY') {
                        return [
                            map { overlay($_, $overlay, $conf) } @$old_ds
                        ];
                    } elsif (reftype($old_ds) eq 'HASH') {
                        return {
                            map {
                                $_ => overlay($old_ds->{$_}, $overlay, $conf)
                            } @$old_ds
                        };
                    } else {
                        return overlay($old_ds, $overlay, $conf);
                    }
                },
    seq     => sub {
                    my ($old_ds, $overlay, $conf) = @_;
                    # XXX reftype $overlay
                    my $ds = $old_ds;
                    for my $ol (@$overlay) {
                        $ds = overlay($ds, $ol, $conf);
                    }
                    return $ds;
                },
);

my %inverse_action = (
    default => 'pop',
    push    => 'pop',
    pop     => 'push',
    shift   => 'unshift',
    unshift => 'shift',
    code    => sub {
                    my ($old_ds, $overlay) = @_;
                    $overlay->{'=inverse'}->($old_ds, $overlay->{'=args'});
                },
    foreach => sub {
                    my ($old_ds, $overlay) = @_;
                    # XXX
                    if (reftype($old_ds) eq 'ARRAY') {
                        return [ map { overlay($_, $overlay) } @$old_ds ];
                    } elsif (reftype($old_ds) eq 'HASH') {
                        return { map {
                                    $_ => overlay($old_ds->{$_}, $overlay)
                                } @$old_ds };
                    } else {
                        return overlay($old_ds, $overlay);
                    }
                },
);

sub overlay_all {
    my ($ds, @overlays) = @_;

    my $min_overlay = compose(@overlays);

    $ds = overlay($ds, $min_overlay);

    return $ds;
}

sub overlay {
    my ($ds, $overlay, $conf) = @_;

    if (reftype($overlay) && reftype($overlay) eq 'HASH') {

        # = is action, == is key with leading =
        my ($keys, $actions, $escaped) = part { /^(==?)/ && length $1 }
                                            sort keys %$overlay;
        die "escaped not handled @$escaped" if $escaped && @$escaped; # XXX
        die "Too many actions @$actions" if $#$actions > 1; # XXX

        if ($actions && @$actions) {
            my ($action) = ($actions->[0] =~ /^=(.*)/);
            die "no action $action" unless exists $action_map{$action};
            return $action_map{$action}->($ds, $overlay->{"=$action"});
        } elsif ($keys && @$keys) {
            my $new_ds;
            if (reftype($ds) && reftype($ds) eq 'HASH') {
                $new_ds = { %$ds }; # shallow copy
            } else {
                $new_ds = {}; # $ds is not a HASH
            }

            for my $key (@$keys) {
                # using $new_ds b/c we already have a shallow copy of hashes
                $new_ds->{$key} =
                    overlay($new_ds->{$key}, $overlay->{$key}, $conf);
            }
            return $new_ds;
        } else {
            # empty overlay hash
            if (defined($ds)) {
                return $ds; # leave $ds alone
            } else {
                return $overlay; # $ds has run out, return empty $overlay {}
            }
        }
    } else {
        # all scalars and non-HASH overlay elements are overrides
        return $overlay;
    }
    confess "A return is missing somewhere";
}

sub compose {
    my (@overlays) = @_;

    # rubbish dumb merger XXX
    return { '=seq' => \@overlays };
}

sub decompose {
}

sub invert {
    my (@overlays) = @_;
    warn "invert not implemented";
    my @new_overlays = reverse @overlays;
    return @new_overlays;
}

__PACKAGE__; # true return
__END__

=head1 NAME

Data::Overlay - merge/overlay data with composable changes

=head1 VERSION

Data::Overlay version 1.01 - format may change, no compatibility promises XXX

=head1 SYNOPSIS

#!perl -s
#line 48

    use strict; use warnings; our $m;
    use Data::Overlay qw(overlay compose);
    use Devel::Peek qw(DumpArray);
    use YAML::XS qw(Dump);


    my $data_structure = {
        a => 123,
        b => {
            w => [ "some", "content" ],
            x => "hello",
            y => \"world",
        },
        c => [ 4, 5, 6],
        d => { da => [], db => undef, dc => qr/abc/ },
    };

    my %edits = (
        f  => 0,                # add key
        a  => '1, 2, 3',        # overwrite key
        'c=unshift' => 3.5,     # prepend array
        'c.1=push' => 7,        # append array
        'd.da' => { },          # replace array
        'b.z'  => [7, 8, 9],    # nested operation
        'd.*' => sub { @_/$_ }, # transform (old, new, path, $_ alias)
        'd.db=default' => 123,  # only update if undef
    );

    # apply %edits in unspecified order
    my $new_data_structure = overlay($data_structure, \%edits);

    print Dump($data_structure, \%edits, $new_data_structure);

    # for memory comparison, run with -m
    DumpArray($data_structure, $new_data_structure) if $m;


=head2 Running SYNOPSIS

Once Data::Overlay is installed, you can run it with either:

    perl -x -MData::Overlay `pmpath Data::Overlay`

    perl -x -MData::Overlay \
        `perl -MData::Overlay -le 'print $INC{"Data/Overlay.pm"}'`

=head1 DESCRIPTION

=head2 Basic Idea

The overlay functions can be used to apply a group of changes
(also called an overlay) to a data structure, non-destructively,
returning a shallow-ish copy with the changes applied.
"Shallow-ish" meaning shallow copies at each level along
the path of the deeper changes.

  $result = overlay($original, $overlay);

The algorithm walks the overlay structure, either taking
values from it, or when nothing has changed, retaining the
values of the original data structure.  This means that the
only the overlay fully traversed.

When the overlay is doesn't use any special Data::Overlay
keys (ones starting with "="), then the result will be
the merger of the original and the overlay, with the overlay
taking precedence.  In particular, only hashes will really
be merged, somewhat like C<< %new = (%defaults, %options) >>,
but recursively.  This means that array refs, scalars, code,
etc. will be replace whatever is in the original, regardless
of the original type (so an array in the overlay will take
precedence over an array, hash or scalar in the original).
That's why it's not called Data::Underlay.

Any different merging behaviour needs to be marked with
special keys in the overlay called "actions".  These start
with an "=" sign.  (Double it in the overlay to have an actual
leading "=" in the result).  The actions are described below,
but they combine the original and overlay in various ways,
pushing/unshifting arrays, only overwriting false or undefined,
up to providing ability to write your own combining callback.

=head2 Memory Sharing

Cloning


=head1 GLOSSARY

overlay - (verb)
        - (noun)

$ds, $old_ds, $new_ds - arbitrary Perl data-structure



=head1 TODO

I'm not sure about the overlay pile, maybe should just be one
overlay at a time to make the client use compose or write
a single one.  That seems a bit mean though.

Self-referential ds & overlays.

=head1 INTERFACE

=head2 overlay

    $new_ds = overlay($old_ds, $overlay);

Apply an overlay to $old_ds, returning $new_ds as the result.

$old_ds is unchanged.  $new_ds may share references to part
of $old_ds (see L<Memory Sharing>).  If this isn't desired
then clone $new_ds.

=head2 overlay_all

    $new_ds = overlay_all($old_ds, $overlay1, $overlay2, ...);

Apply several overlays to $old_ds, returning $new_ds as the result.
They are logically applied left to right, that is $overlay1,
then overlay2, etc.  (Internally C<compose> is used, see next)

=head2 compose

    $combined_overlay = compose($overlay1, $overlay2, ..);

Produce an overlay that has the combined effect of applying
$overlay1 then $overlay2, etc.

=head2 decompose

XXX only possible if compose isn't lossy.
Won't get the input overlays anyway.  Bad idea.

=head2 invert

    $inverted_overlay = invert($overlay);
    $inverted_overlay = invert($overlay, $new_ds);

Tries to find a inverse overlay, one that would reverse
the changes of it's argument.  Similar to reversing a patch.

Most overlays are lossy, they overwrite or push without
keeping track of the discarded values and so are not invertible.
To fill in these gaps, a data structure can be given as a
second argument.  Values will be used from it when needed.
For example, if the overlay does a pop the inverse is
a push, but the value pushed is undefined unless the second
argument is present.

The following sequence should pass the is_deeply test,
except when irreversible operations are in $overlay
(eg. CODE that is =run).

    $new_ds = overlay($old_ds, $overlay);
    $inverted_overlay = invert($overlay, $new_ds);
    $old_ds2 = overlay($new_ds, $inverted_overlay);
    is_deeply($old_ds, $old_ds2);

=head2 underlayXXX

Combines invert and overlay:

  underlayXXX($overlay, $new_ds) === overlay($new_ds, invert($overlay,$old_ds))

=head2 Actions

default // dor def_or
or ||
push pop shift unshift
run code
foreach
seq

defaults {}

config - set local config (override action map / inverse)
exists
delete

and/if/ifthen replace if $ds is true
sprintf prepend_str append_str interpolate $_
+/-/*/++/--/x/%/**/./<</>>
| & ^ ~ masks boolean logic
conditionals? comparison?
deref?
invert apply inverted
swap overlay and ds roles
splitting one ds val into multiple new_ds?
regex matching and extraction
pack/unpack
const?
Objects?
x eval too dangerous
grep


       Functions for SCALARs or strings
           "chomp", "chop", "chr", "crypt", "hex", "index", "lc", "lcfirst",
           "length", "oct", "ord", "pack", "q//", "qq//", "reverse", "rindex",
           "sprintf", "substr", "tr///", "uc", "ucfirst", "y///"

       Regular expressions and pattern matching
           "m//", "pos", "quotemeta", "s///", "split", "study", "qr//"

       Functions for real @ARRAYs
           "pop", "push", "shift", "splice", "unshift"

       Functions for list data
           "grep", "join", "map", "qw//", "reverse", "sort", "unpack"

       Functions for real %HASHes
           "delete", "each", "exists", "keys", "values"

       Functions for fixed length data or records
           "pack", "read", "syscall", "sysread", "syswrite", "unpack", "vec"


       Keywords related to the control flow of your Perl program
           "caller", "continue", "die", "do", "dump", "eval", "exit", "goto",
           "last", "next", "redo", "return", "sub", "wantarray"

       Miscellaneous functions
           "defined", "dump", "eval", "formline", "local", "my", "our",
           "reset", "scalar", "state", "undef", "wantarray"

       Functions new in perl5
           "abs", "bless", "break", "chomp", "chr", "continue", "default",
           "exists", "formline", "given", "glob", "import", "lc", "lcfirst",
           "lock", "map", "my", "no", "our", "prototype", "qr//", "qw//",
           "qx//", "readline", "readpipe", "ref", "sub"*, "sysopen", "tie",
           "tied", "uc", "ucfirst", "untie", "use", "when"



=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

Data::Overlay requires no configuration files or environment variables.

=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.

=head1 BUGS AND LIMITATIONS

I'm happy to hear suggestions, please email them or use RT
in addition to using cpan ratings or annocpan (I'll notice them faster).

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-edit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 See Also

Hash::Merge merge with global options
Data::Utilities
    Data::Merger merge with call-time options
Data::Nested merging (per application options), paths and schemas
Data::ModeMerge

"Path" based access to nested data structures:

Data::Path
Data::DPath
Data::SPath
Data::FetchPath eval-able paths
Class::XPath
CGI::Expand
Data::Hive paths, accessors and better HoH
List::Util C<<reduce { eval { $a->$b } } $object, split(/\./, $_)>>

Lazy deep copying nested data:

Data::COW - Copy on write

Data structure differences:

Data::Diff
Data::Utilities
    Data::Comparator
Data::Rx schema

Data::Visitor retain_magic option Variable::Magic

autovivification

There some overlap between what this module is trying to do
and both the darcs "theory of patches", and operational
transforms.  The overlap is mainly around composing and inverting
changes, but there's nothing particularly concurrent about Data::Overlay.

=head1 KEYWORDS

Merge, edit, overlay, clone, modify, transform, memory sharing,
operational transform, patch,

An SEO expert walked into a bar, tavern, pub...

=head1 AUTHOR

Brad Bowman  C<< <cpan@bereft.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Brad Bowman C<< <cpan@bereft.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
