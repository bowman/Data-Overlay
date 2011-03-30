package Data::Overlay;

use warnings;
use strict;
use Carp;
use Scalar::Util qw(reftype refaddr);
use Exporter 'import';
use YAML::XS; # XXX

our $VERSION = '1.01';
our @EXPORT_OK = qw(id overlay compose);

sub id {
    return shift;
}

sub overlay {
    my ($ds, @overlays) = @_;
    my @min_overlays = compose(@overlays);
    # hoist @overlays to here, only in outer
    # for my $overlay (@min_overlays) { }
    return _overlay($ds, @min_overlays);
}

sub _overlay {
    my ($ds, @overlays) = @_;

# assume HASH for now
    my $reftype = reftype($ds);
    my $new_ds;

    if (!defined $ds) {
        $new_ds = {}; #hass
    } elsif (!$reftype) {
        $new_ds = {}; #hass ??
    } elsif ($reftype eq 'HASH') {
        $new_ds = { %$ds }; # shallow copy
    } else {
        return "Found $reftype";
    }

    for my $overlay (@overlays) {
        for my $segment (sort keys %$overlay) {
            if ($segment =~ /^=(.*)$/) {
                my $action = $1;
                if ($action eq 'default') {
use Carp qw(confess);
warn Dump($new_ds);
                    $new_ds //= $overlay->{$segment};
warn Dump($new_ds);
warn Dump($overlay->{$segment});
#confess "A";
                } elsif ($action eq 'or') {
                    $new_ds ||= $overlay->{$segment};
                } else {
                    die "Bad action";
                }
            } elsif (ref $overlay->{$segment}) {
                if (ref $ds->{$segment}) {
                    $new_ds->{$segment} =
                        _overlay($ds->{$segment}, $overlay->{$segment});
                } else {
                    # $ds exhausted
                    $new_ds->{$segment} =
                        _overlay(undef, $overlay->{$segment});
                }
            } else {
                $new_ds->{$segment} = $overlay->{$segment};
                # overlay may still contain actions
                #$new_ds->{$segment} =
                #    _overlay($ds->{$segment}, $overlay->{$segment});
            }
        }
    }
    return $new_ds;
}

sub compose {
    my (@overlays) = @_;
    my @new_overlays = @overlays;
    return @new_overlays;
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

Data::Overlay version 1.01

=head1 SYNOPSIS

Run the SYNOPSIS with:

    perl -x -MData::Overlay `pmpath Data::Overlay`

#!perl -s
#line 48

    use strict; use warnings; our $m;
    use Data::Overlay qw(id overlay compose);
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
    my $new_data_structure = id($data_structure, \%edits);

    print Dump($data_structure, \%edits, $new_data_structure);

    # for memory comparison, run with -m
    DumpArray($data_structure, $new_data_structure) if $m;

=head1 DESCRIPTION

=head2 Ordering Changes

=head2 Memory Handling and Cloning

=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


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

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Data::Overlay requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

I'm happy to hear suggestions, please email them in addition to using
cpan ratings or annocpan so I notice them faster.

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

=head1 KEYWORDS



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
