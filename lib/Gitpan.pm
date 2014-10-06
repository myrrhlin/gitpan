package Gitpan;

use Gitpan::perl5i;
use Gitpan::OO;
use Gitpan::Types;

use version; our $VERSION = qv("v2.0.0");

use Gitpan::Dist;
use Parallel::ForkManager;

with 'Gitpan::Role::HasBackpanIndex',
     'Gitpan::Role::HasConfig',
     'Gitpan::Role::CanLog';


method import_from_distnames(
    ArrayRef $names,
    Int  :$num_workers           = 2,
    Bool :$delete_repo           = 0,
) {
    my $fork_man = Parallel::ForkManager->new($num_workers);

    my $config = $self->config;

    for my $name (@$names) {
        if( $config->skip_dist($name) ) {
            $self->main_log( "Skipping $name due to config" );
            next;
        }

#        my $pid = $fork_man->start and next;
        $self->import_from_distname(
            $name,
            delete_repo => $delete_repo
        );
#        $fork_man->finish;
    }

    $fork_man->wait_all_children;

    return;
}

method import_from_backpan_dists(
    DBIx::Class::ResultSet $bp_dists,
    Int  :$num_workers  = 2,
    Bool :$delete_repo  = 0
) {
    my $fork_man = Parallel::ForkManager->new($num_workers);

    my $config = $self->config;

    while( my $bp_dist = $bp_dists->next ) {
        my $distname = $bp_dist->name;

        if( $config->skip_dist($distname) ) {
            $self->main_log( "Skipping $distname due to config" );
            next;
        }

        my $dist = Gitpan::Dist->new(
            # Pass in the name to avoid sending an open sqlite connection
            # to the child.
            name => $distname
        );

        my $pid = $fork_man->start and next;
        $self->import_dist($dist, delete_repo => $delete_repo);
        $fork_man->finish;
    }

    $fork_man->wait_all_children;
}


method import_dists(
    ArrayRef :$search_args,
    ArrayRef :$order_by_args,
    Int      :$num_workers      = 2
) {
    my $bp_dists = $self->backpan_index->dists;
    $bp_dists = $bp_dists->search_rs(@$search_args) if $search_args;
    $bp_dists->order_by(@$order_by_args)            if $order_by_args;

    $self->import_from_backpan_dists($bp_dists);

    return;
}


method import_from_distname(
    Str  $name,
    Bool :$delete_repo = 0
) {
    $self->import_dist(
        Gitpan::Dist->new( name => $name ),
        delete_repo => $delete_repo
    );
}


method import_dist(
    Gitpan::Dist $dist,
    Bool :$delete_repo = 0,
) {
    $dist->delete_repo if $delete_repo;
    $dist->import_releases;
}
